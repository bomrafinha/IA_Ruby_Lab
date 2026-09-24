module AiLab
  class ExperimentRunner
    DEFAULT_TENSOR_VALUES = [2.0, 4.0, 6.0, 8.0, 10.0].freeze

    def self.call(experiment, params = {})
      new(experiment, params).call
    end

    def initialize(experiment, params)
      @experiment = experiment
      @params = params
    end

    def call
      return unavailable_result unless @experiment.available?

      case @experiment.slug
      when "regressao-linear"
        run_linear_regression
      when "tensores"
        run_tensor_operations
      else
        unavailable_result
      end
    end

    private

    def run_linear_regression
      require "rumale"

      features = Numo::DFloat[[1.0], [2.0], [3.0], [4.0], [5.0]]
      targets = Numo::DFloat[3.0, 5.0, 7.0, 9.0, 11.0]
      model = Rumale::LinearModel::LinearRegression.new
      model.fit(features, targets)

      sample = numeric_param(:sample, 6.0)
      prediction = model.predict(Numo::DFloat[[sample]]).to_a.flatten.first
      intercept = model.predict(Numo::DFloat[[0.0]]).to_a.flatten.first
      slope = model.predict(Numo::DFloat[[1.0]]).to_a.flatten.first - intercept

      {
        kind: :result,
        title: "Modelo treinado",
        equation: format("y = %.2fx %+.2f", slope, intercept),
        stats: [
          { label: "R²", value: format("%.3f", model.score(features, targets)) },
          { label: "Amostras", value: features.shape[0].to_s },
          { label: "Previsão", value: format("%.2f", prediction) }
        ],
        note: "Para x = #{format("%.2f", sample)}, o modelo estima y = #{format("%.2f", prediction)}.",
        source: "model = Rumale::LinearModel::LinearRegression.new\nmodel.fit(features, targets)\nmodel.predict([[6.0]])"
      }
    end

    def run_tensor_operations
      require "torch"

      values = tensor_values
      tensor = Torch.tensor(values)
      mean = tensor.mean.item.to_f
      variance = ((tensor - mean) * (tensor - mean)).mean.item.to_f

      {
        kind: :result,
        title: "Tensor analisado",
        equation: tensor.inspect,
        stats: [
          { label: "Elementos", value: values.length.to_s },
          { label: "Média", value: format("%.2f", mean) },
          { label: "Variância", value: format("%.2f", variance) }
        ],
        note: "O tensor foi centralizado em torno da média antes do cálculo da variância.",
        source: "tensor = Torch.tensor(#{values.inspect})\nmean = tensor.mean\nvariance = ((tensor - mean) ** 2).mean"
      }
    end

    def unavailable_result
      {
        kind: :soon,
        title: "Aula em preparação",
        note: "Este espaço já está reservado no catálogo e receberá um novo algoritmo."
      }
    end

    def tensor_values
      values = @params[:values] || @params["values"]
      parsed = values.to_s.split(",").filter_map do |value|
        Float(value.strip)
      rescue ArgumentError, TypeError
        nil
      end

      parsed.first(12).presence || DEFAULT_TENSOR_VALUES
    end

    def numeric_param(name, fallback)
      value = @params[name] || @params[name.to_s]
      Float(value)
    rescue ArgumentError, TypeError
      fallback
    end
  end
end
