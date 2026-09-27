require "rumale"

module AiLab
  module Experiments
    class RumaleAdapter < Base
      CLASSIFICATION_VALUES = Numo::DFloat[
        [ 0.0, 0.0 ], [ 0.0, 1.0 ], [ 1.0, 0.0 ], [ 1.0, 1.0 ], [ 2.0, 1.0 ], [ 1.0, 2.0 ]
      ].freeze
      CLUSTERING_VALUES = Numo::DFloat[
        [ 0.0, 0.1 ], [ 0.1, 0.0 ], [ -0.1, 0.0 ], [ 0.0, -0.1 ], [ 0.2, 0.1 ], [ -0.2, -0.1 ],
        [ 5.0, 5.1 ], [ 5.1, 5.0 ], [ 4.9, 5.0 ], [ 5.0, 4.9 ], [ 5.2, 5.1 ], [ 4.8, 4.9 ]
      ].freeze
      CLASSIFICATION_TARGETS = Numo::Int32[0, 0, 1, 1, 1, 1].freeze
      REGRESSION_TARGETS = Numo::DFloat[1.0, 2.0, 3.0, 4.0, 5.0, 6.0].freeze
      BOOSTING_VALUES = Numo::DFloat[
        [ 1.0, 0.0 ], [ 2.0, 1.0 ], [ 3.0, 0.0 ], [ 4.0, 1.0 ],
        [ 5.0, 0.0 ], [ 6.0, 1.0 ], [ 7.0, 0.0 ], [ 8.0, 1.0 ]
      ].freeze
      BOOSTING_TARGETS = Numo::DFloat[10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0].freeze

      def call
        constant = resolve_constant(experiment.api_name)
        return run_precision_recall if experiment.api_name.end_with?("PrecisionRecall")
        return inspection_result(constant) unless constant.respond_to?(:new)
        return run_legacy_linear_regression(constant) if experiment.slug == "regressao-linear"
        return run_kernel_machine(constant) if experiment.api_name.include?("KernelMachine")
        return run_pipeline(constant) if experiment.api_name.include?("Pipeline")

        if experiment.category.to_s.include?("Seleção de modelo e métricas")
          return run_selection_or_metric(constant)
        end

        if experiment.category.to_s.match?("Atributos|Redução de dimensionalidade")
          return run_transformer(constant)
        end

        if experiment.category.to_s.include?("Clustering")
          return run_clustering(constant)
        end

        run_estimator(constant)
      end

      private

      def run_legacy_linear_regression(constant)
        features = Numo::DFloat[[ 1.0 ], [ 2.0 ], [ 3.0 ], [ 4.0 ], [ 5.0 ]]
        targets = Numo::DFloat[3.0, 5.0, 7.0, 9.0, 11.0]
        model = constant.new
        model.fit(features, targets)

        sample = numeric_param(:sample, 6.0)
        prediction = model.predict(Numo::DFloat[[ sample ]]).to_a.flatten.first
        intercept = model.predict(Numo::DFloat[[ 0.0 ]]).to_a.flatten.first
        slope = model.predict(Numo::DFloat[[ 1.0 ]]).to_a.flatten.first - intercept
        fitted_values = model.predict(features).to_a.flatten

        result(
          title: "Modelo treinado",
          equation: format("y = %.2fx %+.2f", slope, intercept),
          stats: [
            { label: "R²", value: format("%.3f", model.score(features, targets)) },
            { label: "Amostras", value: features.shape[0].to_s },
            { label: "Previsão", value: format("%.2f", prediction) }
          ],
          note: "Para x = #{format("%.2f", sample)}, o modelo estima y = #{format("%.2f", prediction)}.",
          source: "model = Rumale::LinearModel::LinearRegression.new\nmodel.fit(features, targets)\nmodel.predict([[#{sample}]])",
          chart: line_chart(
            labels: features.to_a.flatten,
            series: [
              { label: "alvo", data: targets.to_a },
              { label: "previsão", data: fitted_values }
            ]
          )
        )
      end

      def run_estimator(constant)
        model = instantiate(constant)
        classification = classifier_api?
        features = experiment.api_name.end_with?("AdaBoostRegressor") ? BOOSTING_VALUES : CLASSIFICATION_VALUES
        targets = if classification
          CLASSIFICATION_TARGETS
        elsif experiment.api_name.end_with?("AdaBoostRegressor")
          BOOSTING_TARGETS
        else
          REGRESSION_TARGETS
        end

        if experiment.api_name.end_with?("GradientTreeRegressor")
          gradients = Numo::DFloat.ones(features.shape[0])
          hessians = Numo::DFloat.ones(features.shape[0])
          model.fit(features, targets, gradients, hessians)
        else
          model.fit(features, targets)
        end
        predictions = model.respond_to?(:predict) ? model.predict(features) : model.transform(features)
        values = flat_values(predictions)
        score = if classification
          accuracy(CLASSIFICATION_TARGETS.to_a, values)
        else
          format("%.3f", r2_score(REGRESSION_TARGETS.to_a, values.map(&:to_f)))
        end

        result(
          title: "#{human_api_name} executado",
          equation: values.first(6).inspect,
          stats: [
            { label: "Amostras", value: features.shape[0].to_s },
            { label: classification ? "Acerto" : "R²", value: classification ? "#{score}%" : score },
            { label: "API", value: short_api_name }
          ],
          note: "O exemplo ajustou #{short_api_name} com dados pequenos e determinísticos.",
          source: "model = #{experiment.api_name}.new\nmodel.fit(features, targets)\nmodel.predict(features)",
          chart: line_chart(
            labels: (1..values.length).to_a,
            series: [ { label: "saída", data: values } ]
          )
        )
      end

      def run_transformer(constant)
        transformer = instantiate(constant)
        features, targets = transformer_fixture
        output = if transformer.respond_to?(:fit_transform)
          fit_transform(transformer, features, targets)
        else
          transformer.fit(features, targets)
          transformer.respond_to?(:transform) ? transformer.transform(features) : features
        end
        values = flat_values(output)
        input_size = features.respond_to?(:shape) ? features.shape.join(" × ") : features.length.to_s

        result(
          title: "#{human_api_name} aplicado",
          equation: values.first(12).inspect,
          stats: [
            { label: "Entrada", value: input_size },
            { label: "Saída", value: values.length.to_s },
            { label: "API", value: short_api_name }
          ],
          note: "A transformação foi executada sobre um fixture local; a saída mostra os primeiros valores.",
          source: "transformer = #{experiment.api_name}.new\ntransformer.fit_transform(features)",
          chart: bar_chart(labels: (1..values.length).to_a, values: values)
        )
      end

      def run_kernel_machine(constant)
        kernel_matrix = CLASSIFICATION_VALUES.dot(CLASSIFICATION_VALUES.transpose)
        model = instantiate(constant)
        model.fit(kernel_matrix, CLASSIFICATION_TARGETS)
        predictions = model.predict(kernel_matrix)
        values = flat_values(predictions)

        result(
          title: "#{human_api_name} executado",
          equation: values.inspect,
          stats: [
            { label: "Amostras", value: kernel_matrix.shape[0].to_s },
            { label: "Matriz", value: kernel_matrix.shape.join(" × ") },
            { label: "API", value: short_api_name }
          ],
          note: "O modelo recebeu uma matriz de similaridade linear quadrada construída a partir dos pontos do fixture.",
          source: "kernel = features.dot(features.transpose)\nmodel = #{experiment.api_name}.new\nmodel.fit(kernel, targets)",
          chart: line_chart(labels: (1..values.length).to_a, series: [ { label: "previsão", data: values } ])
        )
      end

      def run_pipeline(constant)
        if experiment.api_name.end_with?("Pipeline")
          pipeline = constant.new(
            steps: {
              scale: Rumale::Preprocessing::StandardScaler.new,
              model: Rumale::LinearModel::LinearRegression.new
            }
          )
          pipeline.fit(CLASSIFICATION_VALUES, REGRESSION_TARGETS)
          values = flat_values(pipeline.predict(CLASSIFICATION_VALUES))
        else
          union = constant.new(
            transformers: {
              standard: Rumale::Preprocessing::StandardScaler.new,
              range: Rumale::Preprocessing::MinMaxScaler.new
            }
          )
          values = flat_values(union.fit_transform(CLASSIFICATION_VALUES))
        end

        result(
          title: "#{human_api_name} executado",
          equation: values.first(12).inspect,
          stats: [
            { label: "Entrada", value: CLASSIFICATION_VALUES.shape.join(" × ") },
            { label: "Saída", value: values.length.to_s },
            { label: "API", value: short_api_name }
          ],
          note: "A composição foi executada com transformadores Rumale reais e um fixture determinístico.",
          source: "pipeline = #{experiment.api_name}.new(steps: {...})\npipeline.fit(features, targets)",
          chart: bar_chart(labels: (1..[ values.length, 12 ].min).to_a, values: values.first(12))
        )
      end

      def run_clustering(constant)
        model = instantiate(constant)
        labels = if model.respond_to?(:fit_predict)
          model.fit_predict(CLUSTERING_VALUES)
        else
          model.fit(CLUSTERING_VALUES)
          model.respond_to?(:labels) ? model.labels : model.predict(CLUSTERING_VALUES)
        end
        values = flat_values(labels)

        result(
          title: "#{human_api_name} agrupou os pontos",
          equation: values.inspect,
          stats: [
            { label: "Pontos", value: CLUSTERING_VALUES.shape[0].to_s },
            { label: "Grupos", value: values.uniq.length.to_s },
            { label: "API", value: short_api_name }
          ],
          note: "Cada número representa o grupo atribuído ao ponto correspondente.",
          source: "model = #{experiment.api_name}.new\nlabels = model.fit_predict(features)",
          chart: scatter_chart(
            points: CLUSTERING_VALUES.to_a.each_with_index.map { |point, index| [ point[0], point[1], index ] },
            groups: values
          )
        )
      end

      def run_selection_or_metric(constant)
        return run_metric(constant) if experiment.api_name.include?("EvaluationMeasure")
        return run_model_selection(constant) if experiment.api_name.match?("GridSearchCV|CrossValidation")

        splitter = instantiate(constant)
        splits = if splitter.respond_to?(:split)
          if splitter.method(:split).parameters.length >= 3
            splitter.split(CLASSIFICATION_VALUES, CLASSIFICATION_TARGETS, Numo::Int32[0, 0, 1, 1, 2, 2]).to_a
          else
            splitter.split(CLASSIFICATION_VALUES, CLASSIFICATION_TARGETS).to_a
          end
        else
          []
        end

        result(
          title: "#{human_api_name} criou divisões",
          equation: splits.map { |train, test| "#{train.length}/#{test.length}" }.join(" · "),
          stats: [
            { label: "Divisões", value: splits.length.to_s },
            { label: "Amostras", value: CLASSIFICATION_VALUES.shape[0].to_s },
            { label: "API", value: short_api_name }
          ],
          note: "O splitter foi executado sem treinar um modelo, mantendo a separação entre avaliação e treino.",
          source: "splitter = #{experiment.api_name}.new\nsplitter.split(features, targets)",
          chart: bar_chart(
            labels: (1..splits.length).map { |index| "split #{index}" },
            values: splits.map { |train, _test| train.length }
          )
        )
      end

      def run_precision_recall
        true_values = Numo::Int32[0, 1, 1, 0]
        predicted_values = Numo::Int32[0, 1, 0, 0]
        value = Rumale::EvaluationMeasure::PrecisionRecall.micro_average_f_score(true_values, predicted_values)

        result(
          title: "#{human_api_name} calculada",
          equation: value.inspect,
          stats: [
            { label: "F-score", value: format_value(value) },
            { label: "Pares", value: true_values.length.to_s },
            { label: "API", value: short_api_name }
          ],
          note: "O módulo calculou o F-score médio diretamente sobre os rótulos Numo do fixture.",
          source: "Rumale::EvaluationMeasure::PrecisionRecall.micro_average_f_score(y_true, y_pred)",
          chart: bar_chart(labels: [ "f-score" ], values: [ value ])
        )
      end

      def run_model_selection(constant)
        estimator = Rumale::LinearModel::LogisticRegression.new(max_iter: 50)
        splitter = Rumale::ModelSelection::StratifiedKFold.new(n_splits: 2, random_seed: 7)
        evaluator = Rumale::EvaluationMeasure::Accuracy.new

        if experiment.api_name.end_with?("GridSearchCV")
          search = constant.new(
            estimator: estimator,
            param_grid: { reg_param: [ 0.1, 1.0 ] },
            splitter: splitter,
            evaluator: evaluator
          )
          search.fit(CLASSIFICATION_VALUES, CLASSIFICATION_TARGETS)
          values = search.cv_results[:mean_test_score].map(&:to_f)
          note = "A busca testou reg_param e escolheu #{search.best_params.inspect} com score #{format_value(search.best_score)}."
        else
          validation = constant.new(estimator: estimator, splitter: splitter, evaluator: evaluator, return_train_score: true)
          report = validation.perform(CLASSIFICATION_VALUES, CLASSIFICATION_TARGETS)
          values = report[:test_score].map(&:to_f)
          note = "A validação cruzada produziu scores por divisão sem misturar as amostras de treino e teste."
        end

        result(
          title: "#{human_api_name} executada",
          equation: values.inspect,
          stats: [
            { label: "Divisões", value: values.length.to_s },
            { label: "Melhor score", value: format_value(values.max) },
            { label: "API", value: short_api_name }
          ],
          note: note,
          source: "selector = #{experiment.api_name}.new(...)\nselector.fit(features, targets)",
          chart: bar_chart(labels: (1..values.length).map { |index| "fold #{index}" }, values: values)
        )
      end

      def run_metric(constant)
        metric = instantiate(constant)
        true_values = Numo::Int32[0, 1, 1, 0]
        predicted_values = Numo::Int32[0, 1, 0, 0]
        value = if experiment.api_name.include?("ROCAUC")
          metric.score(true_values, Numo::DFloat[0.1, 0.8, 0.7, 0.2])
        elsif experiment.api_name.include?("LogLoss")
          metric.score(true_values, Numo::DFloat[0.2, 0.8, 0.7, 0.1])
        elsif experiment.api_name.match?("CalinskiHarabaszScore|DaviesBouldinScore")
          metric.score(CLUSTERING_VALUES, Numo::Int32[0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1])
        elsif experiment.api_name.include?("Silhouette")
          metric.score(CLUSTERING_VALUES, Numo::Int32[0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1])
        else
          metric.score(true_values, predicted_values)
        end

        result(
          title: "#{human_api_name} calculada",
          equation: value.inspect,
          stats: [
            { label: "Valor", value: format_value(value) },
            { label: "Pares", value: true_values.length.to_s },
            { label: "API", value: short_api_name }
          ],
          note: "A medida foi calculada sobre rótulos pequenos para tornar o resultado fácil de conferir.",
          source: "metric = #{experiment.api_name}.new\nmetric.score(y_true, y_pred)",
          chart: bar_chart(labels: [ "score" ], values: [ value ])
        )
      end

      def instantiate(constant)
        case constant.name
        when "Rumale::ModelSelection::StratifiedKFold", "Rumale::ModelSelection::StratifiedShuffleSplit"
          return constant.new(n_splits: 2, random_seed: 7)
        when "Rumale::ModelSelection::GroupKFold"
          return constant.new(n_splits: 3)
        when "Rumale::ModelSelection::GroupShuffleSplit"
          return constant.new(n_splits: 3, random_seed: 7)
        when "Rumale::Clustering::KMeans", "Rumale::Clustering::MiniBatchKMeans", "Rumale::Clustering::KMedoids",
             "Rumale::Clustering::SpectralClustering", "Rumale::Clustering::GaussianMixture"
          return constant.new(n_clusters: 2, random_seed: 7)
        when "Rumale::Clustering::HDBSCAN"
          return constant.new(min_samples: 2, min_cluster_size: 2)
        when "Rumale::Clustering::SNN"
          return constant.new(n_neighbors: 2, min_samples: 2)
        when "Rumale::Clustering::DBSCAN"
          return constant.new(eps: 0.5, min_samples: 2)
        when "Rumale::Ensemble::VotingClassifier"
          return constant.new(estimators: {
            linear: Rumale::LinearModel::LogisticRegression.new(max_iter: 50),
            tree: Rumale::Tree::DecisionTreeClassifier.new(max_depth: 2, random_seed: 7)
          })
        when "Rumale::Ensemble::VotingRegressor"
          return constant.new(estimators: {
            linear: Rumale::LinearModel::LinearRegression.new,
            tree: Rumale::Tree::DecisionTreeRegressor.new(max_depth: 2, random_seed: 7)
          })
        when "Rumale::Ensemble::AdaBoostRegressor"
          return constant.new(n_estimators: 3, threshold: 0.2, max_depth: 2, random_seed: 7)
        when "Rumale::Ensemble::StackingClassifier"
          return constant.new(
            estimators: { linear: Rumale::LinearModel::LogisticRegression.new(max_iter: 50) },
            n_splits: 2,
            random_seed: 7
          )
        when "Rumale::Ensemble::StackingRegressor"
          return constant.new(
            estimators: { linear: Rumale::LinearModel::LinearRegression.new },
            n_splits: 3,
            random_seed: 7
          )
        when "Rumale::Pipeline::Pipeline"
          return constant.new(steps: {})
        when "Rumale::Pipeline::FeatureUnion"
          return constant.new(transformers: {})
        end

        required = constant.instance_method(:initialize).parameters.select { |kind, _| kind == :keyreq }
        return constant.new unless required.any?

        raise ArgumentError, "#{constant.name} exige composição explícita"
      end

      def transformer_fixture
        if experiment.api_name.to_s.match?("FeatureHasher|HashVectorizer")
          return [
            { language: "ruby", topic: "ia", samples: 3.0 },
            { language: "ruby", topic: "dados", samples: 2.0 },
            { language: "dados", topic: "modelo", samples: 1.0 }
          ], nil
        end

        if experiment.api_name.to_s.match?("LabelEncoder|LabelBinarizer")
          return [ "azul", "verde", "azul", "vermelho" ], nil
        end

        [ CLASSIFICATION_VALUES, CLASSIFICATION_TARGETS ]
      end

      def fit_transform(transformer, features, targets)
        return transformer.fit_transform(features, targets) if targets && accepts_two_arguments?(transformer, :fit_transform)

        transformer.fit_transform(features)
      end

      def accepts_two_arguments?(object, method_name)
        parameters = object.method(method_name).parameters
        parameters.any? { |kind, _| %i[req opt].include?(kind) } && parameters.length >= 2
      end

      def classifier_api?
        experiment.api_name.match?("Classifier|SVC|NB|FisherDiscriminant|NeighbourhoodComponent")
      end

      def accuracy(expected, actual)
        return 0 if expected.empty?

        ((expected.zip(actual).count { |left, right| left.to_i == right.to_i }.to_f / expected.length) * 100).round
      end

      def r2_score(expected, actual)
        mean = expected.sum / expected.length
        total = expected.sum { |value| (value - mean)**2 }
        residual = expected.zip(actual).sum { |left, right| (left - right)**2 }
        total.zero? ? 0.0 : 1.0 - (residual / total)
      end

      def numeric_param(name, fallback)
        value = params[name] || params[name.to_s]
        Float(value)
      rescue ArgumentError, TypeError
        fallback
      end
    end
  end
end
