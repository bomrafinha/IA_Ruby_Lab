require "torch"
require "tempfile"

module AiLab
  module Experiments
    class TorchAdapter < Base
      DEFAULT_TENSOR_VALUES = [ 2.0, 4.0, 6.0, 8.0, 10.0 ].freeze
      STRUCTURAL_MODULES = %w[
        Module ModuleList ParameterList ConvNd AvgPoolNd AdaptiveAvgPoolNd MaxPoolNd AdaptiveMaxPoolNd
        MaxUnpoolNd LPPoolNd DropoutNd ConstantPadNd ReflectionPadNd ReplicationPadNd
        BatchNorm InstanceNorm Parameter
      ].freeze
      UNAVAILABLE_MODULES = %w[MaxUnpool1d MaxUnpool2d MaxUnpool3d LPPool1d LPPool2d].freeze

      def call
        return run_tensor_operations if experiment.api_name == "Torch.tensor"
        return run_neural_module if experiment.api_name.to_s.start_with?("Torch::NN::")
        return run_optimizer if experiment.api_name.to_s.start_with?("Torch::Optim::")
        return run_distribution if experiment.api_name.to_s.start_with?("Torch::Distributions::")
        return run_data if experiment.api_name.to_s.start_with?("Torch::Utils::Data::")

        run_api
      end

      private

      def run_tensor_operations
        values = tensor_values
        tensor = Torch.tensor(values)
        mean = tensor.mean.item.to_f
        variance = ((tensor - mean) * (tensor - mean)).mean.item.to_f

        result(
          title: "Tensor analisado",
          equation: tensor.inspect,
          stats: [
            { label: "Elementos", value: values.length.to_s },
            { label: "Média", value: format("%.2f", mean) },
            { label: "Variância", value: format("%.2f", variance) }
          ],
          note: "O tensor foi centralizado em torno da média antes do cálculo da variância.",
          source: "tensor = Torch.tensor(#{values.inspect})\nmean = tensor.mean\nvariance = ((tensor - mean) ** 2).mean",
          chart: bar_chart(labels: (1..values.length).to_a, values: values)
        )
      end

      def run_api
        return run_tensor_operations if experiment.api_name.nil?

        if experiment.api_name.start_with?("Torch.")
          return run_function(experiment.api_name.delete_prefix("Torch."))
        end

        constant = resolve_constant(experiment.api_name)
        inspection_result(constant, "A API foi resolvida no LibTorch; esta entrada é um namespace ou utilitário de infraestrutura.")
      end

      def run_function(name)
        return run_autograd_function if name == "backward"
        return run_no_grad_function if name == "no_grad"
        return run_serialization_function(name) if %w[save load].include?(name)
        return run_state_dict if name == "state_dict"

        if Torch.respond_to?(name)
          value = torch_function_call(name)
          return result(
            title: "Torch.#{name} executado",
            equation: value.inspect,
            stats: [
              { label: "API", value: "Torch.#{name}" },
              { label: "Tipo", value: value.class.name.to_s.split("::").last },
              { label: "Observação", value: "CPU" }
            ],
            note: "A função foi chamada com uma entrada pequena e segura para demonstração.",
            source: "Torch.#{name}(...)",
            chart: bar_chart(labels: (1..numeric_values(value).length).to_a, values: numeric_values(value))
          )
        end

        tensor = Torch.tensor(DEFAULT_TENSOR_VALUES)
        if tensor.respond_to?(name)
          value = tensor.public_send(name)
          return result(
            title: "Tensor.#{name} executado",
            equation: value.inspect,
            stats: [
              { label: "API", value: "Tensor.#{name}" },
              { label: "Entrada", value: DEFAULT_TENSOR_VALUES.length.to_s },
              { label: "Tipo", value: value.class.name.to_s.split("::").last }
            ],
            note: "A operação foi aplicada ao tensor padrão do laboratório.",
            source: "tensor = Torch.tensor(#{DEFAULT_TENSOR_VALUES.inspect})\ntensor.#{name}",
            chart: bar_chart(labels: (1..numeric_values(value).length).to_a, values: numeric_values(value))
          )
        end

        inspection_result(nil, "A entrada está documentada, mas não é um método invocável diretamente neste namespace da versão instalada.")
      end

      def run_autograd_function
        tensor = Torch.tensor([ 1.0, 2.0 ], requires_grad: true)
        total = tensor.sum
        total.backward

        result(
          title: "Autograd executado",
          equation: total.inspect,
          stats: [
            { label: "Entrada", value: "2" },
            { label: "Saída", value: format_value(total) },
            { label: "API", value: "backward" }
          ],
          note: "O backward percorreu o grafo criado pelo tensor e calculou a soma diferenciável.",
          source: "tensor = Torch.tensor([1.0, 2.0], requires_grad: true)\ntensor.sum.backward",
          chart: bar_chart(labels: [ "1", "2" ], values: [ 1.0, 1.0 ])
        )
      end

      def run_no_grad_function
        value = Torch.no_grad { Torch.tensor([ 1.0, 2.0 ]) * 2 }

        result(
          title: "no_grad executado",
          equation: value.inspect,
          stats: [
            { label: "Elementos", value: numeric_values(value).length.to_s },
            { label: "Gradiente", value: "desativado" },
            { label: "API", value: "no_grad" }
          ],
          note: "A operação ocorreu em um bloco sem rastreamento de gradientes.",
          source: "Torch.no_grad { Torch.tensor([1.0, 2.0]) * 2 }",
          chart: bar_chart(labels: [ "1", "2" ], values: numeric_values(value))
        )
      end

      def run_serialization_function(name)
        file = Tempfile.new([ "ia-lab", ".pt" ])
        path = file.path
        file.close
        tensor = Torch.tensor([ 1.0, 2.0 ])
        loaded = if name == "save"
          Torch.save(tensor, path)
          tensor
        else
          Torch.save(tensor, path)
          Torch.load(path)
        end

        result(
          title: "Torch.#{name} executado",
          equation: loaded.inspect,
          stats: [
            { label: "Elementos", value: numeric_values(loaded).length.to_s },
            { label: "Arquivo", value: "temporário" },
            { label: "API", value: "Torch.#{name}" }
          ],
          note: "O tensor foi serializado em um arquivo temporário e mantido fora do banco do laboratório.",
          source: "Torch.save(tensor, path)\nTorch.load(path)",
          chart: bar_chart(labels: [ "1", "2" ], values: numeric_values(loaded))
        )
      ensure
        file&.unlink
      end

      def run_state_dict
        model = Torch::NN::Linear.new(2, 1)
        state = model.state_dict
        values = state.values.flat_map { |value| numeric_values(value) }.first(12)

        result(
          title: "state_dict inspecionado",
          equation: state.keys.inspect,
          stats: [
            { label: "Parâmetros", value: state.keys.length.to_s },
            { label: "Valores", value: values.length.to_s },
            { label: "API", value: "state_dict" }
          ],
          note: "O state_dict foi obtido de uma camada Linear real e seus pesos foram usados no gráfico.",
          source: "model = Torch::NN::Linear.new(2, 1)\nmodel.state_dict",
          chart: bar_chart(labels: (1..values.length).to_a, values: values)
        )
      end

      def run_neural_module
        constant = resolve_constant(experiment.api_name)
        short_name = experiment.api_name.split("::").last

        return inspection_result(constant, "Esta é uma classe base ou contêiner; ela organiza módulos, mas não representa uma operação numérica isolada.") if STRUCTURAL_MODULES.include?(short_name)
        return unavailable_result("Esta operação está exposta pela classe Torch.rb, mas o binding instalado ainda não implementa seu operador nativo.") if UNAVAILABLE_MODULES.include?(short_name)
        return run_linear(constant) if short_name == "Linear"
        return run_init if short_name == "Init"
        return run_transformer(constant) if short_name == "Transformer"
        return run_upsample(constant) if short_name == "Upsample"
        return run_softmax_2d(constant) if short_name == "Softmax2d"
        return run_similarity(constant) if %w[CosineSimilarity PairwiseDistance].include?(short_name)
        return run_special_loss(constant, short_name) if %w[
          CTCLoss CosineEmbeddingLoss MarginRankingLoss MultiLabelMarginLoss
          MultiMarginLoss MultiLabelSoftMarginLoss TripletMarginLoss WeightedLoss
        ].include?(short_name)
        return run_loss(constant) if short_name.end_with?("Loss")
        return run_configured_module(constant, short_name)

        module_instance = instantiate_module(constant, short_name)
        return inspection_result(constant, "#{short_name} foi resolvido; seu construtor requer dimensões ou hiperparâmetros próprios.") unless module_instance

        input = Torch.tensor([ [ 1.0, 2.0 ], [ 2.0, 1.0 ] ])
        output = module_instance.respond_to?(:forward) ? module_instance.forward(input) : module_instance
        result(
          title: "#{human_api_name} executado",
          equation: output.inspect,
          stats: [
            { label: "API", value: short_api_name },
            { label: "Entrada", value: "2 × 2" },
            { label: "Tipo", value: output.class.name.to_s.split("::").last }
          ],
          note: "O módulo recebeu uma entrada pequena; arquiteturas com dimensões especiais exibem sua assinatura quando necessário.",
          source: "layer = #{experiment.api_name}.new(...)\nlayer.forward(input)",
          chart: line_chart(labels: (1..numeric_values(output).length).to_a, series: [ { label: "saída", data: numeric_values(output) } ])
        )
      end

      def run_configured_module(constant, short_name)
        value = case short_name
        when "Bilinear"
          constant.new(2, 2, 1).forward(Torch.tensor([ [ 1.0, 2.0 ] ]), Torch.tensor([ [ 2.0, 1.0 ] ]))
        when "Conv1d"
          constant.new(1, 1, 2).forward(Torch.tensor([ [ [ 1.0, 2.0, 3.0, 4.0 ] ] ]))
        when "Conv2d"
          constant.new(1, 1, 2).forward(Torch.ones([ 1, 1, 4, 4 ]))
        when "Conv3d"
          constant.new(1, 1, 2).forward(Torch.ones([ 1, 1, 4, 4, 4 ]))
        when "RNN", "GRU", "LSTM"
          extract_primary(constant.new(2, 2, num_layers: 1, batch_first: true).forward(sequence_tensor))
        when "MultiheadAttention"
          extract_primary(constant.new(2, 1, batch_first: true).forward(sequence_tensor, sequence_tensor, sequence_tensor))
        when "TransformerEncoderLayer"
          constant.new(2, 1, batch_first: true).forward(sequence_tensor)
        when "TransformerEncoder"
          layer = Torch::NN::TransformerEncoderLayer.new(2, 1, batch_first: true)
          constant.new(layer, 1).forward(sequence_tensor)
        when "TransformerDecoderLayer"
          constant.new(2, 1, batch_first: true).forward(sequence_tensor, sequence_tensor)
        when "TransformerDecoder"
          layer = Torch::NN::TransformerDecoderLayer.new(2, 1, batch_first: true)
          constant.new(layer, 1).forward(sequence_tensor, sequence_tensor)
        when "Embedding"
          constant.new(5, 2).forward(Torch.tensor([ 0, 1 ], dtype: Torch.int64))
        when "EmbeddingBag"
          constant.new(5, 2).forward(
            Torch.tensor([ 0, 1 ], dtype: Torch.int64),
            offsets: Torch.tensor([ 0 ], dtype: Torch.int64)
          )
        when "BatchNorm", "BatchNorm1d"
          constant.new(2).forward(Torch.tensor([ [ 1.0, 2.0 ], [ 2.0, 3.0 ] ]))
        when "BatchNorm2d", "GroupNorm", "InstanceNorm", "InstanceNorm2d"
          normalizer = short_name == "GroupNorm" ? constant.new(1, 2) : constant.new(2)
          normalizer.forward(Torch.ones([ 1, 2, 2, 2 ]))
        when "BatchNorm3d", "InstanceNorm3d"
          constant.new(2).forward(Torch.ones([ 1, 2, 2, 2, 2 ]))
        when "InstanceNorm1d"
          constant.new(2).forward(Torch.ones([ 1, 2, 4 ]))
        when "LayerNorm"
          constant.new([ 2 ]).forward(Torch.tensor([ [ 1.0, 2.0 ], [ 2.0, 3.0 ] ]))
        when "LocalResponseNorm"
          constant.new(2).forward(Torch.ones([ 1, 2, 2, 2 ]))
        when "AvgPool1d", "MaxPool1d", "LPPool1d"
          pooling = short_name == "LPPool1d" ? constant.new(2, 2) : constant.new(2)
          pooling.forward(Torch.tensor([ [ [ 1.0, 2.0, 3.0, 4.0 ] ] ]))
        when "AvgPool2d", "MaxPool2d", "LPPool2d"
          pooling = short_name == "LPPool2d" ? constant.new(2, 2) : constant.new([ 2, 2 ])
          pooling.forward(Torch.ones([ 1, 1, 4, 4 ]))
        when "AvgPool3d", "MaxPool3d"
          constant.new([ 2, 2, 2 ]).forward(Torch.ones([ 1, 1, 4, 4, 4 ]))
        when "AdaptiveAvgPool1d", "AdaptiveMaxPool1d"
          constant.new(2).forward(Torch.tensor([ [ [ 1.0, 2.0, 3.0, 4.0 ] ] ]))
        when "AdaptiveAvgPool2d", "AdaptiveMaxPool2d"
          extract_primary(constant.new([ 2, 2 ]).forward(Torch.ones([ 1, 1, 4, 4 ])))
        when "AdaptiveAvgPool3d", "AdaptiveMaxPool3d"
          extract_primary(constant.new([ 2, 2, 2 ]).forward(Torch.ones([ 1, 1, 4, 4, 4 ])))
        when "MaxUnpool1d"
          unpool_with_indices(constant, 1, [ [ [ 1.0, 2.0, 3.0, 4.0 ] ] ])
        when "MaxUnpool2d"
          unpool_with_indices(constant, 2, [ [ [ [ 1.0, 2.0 ], [ 3.0, 4.0 ] ] ] ])
        when "MaxUnpool3d"
          unpool_with_indices(constant, 3, [ [ [ [ [ 1.0, 2.0 ], [ 3.0, 4.0 ] ], [ [ 5.0, 6.0 ], [ 7.0, 8.0 ] ] ] ] ])
        when "Dropout", "Dropout2d", "Dropout3d", "AlphaDropout", "FeatureAlphaDropout"
          constant.new(p: 0.0).forward(Torch.ones([ 1, 1, 2, 2 ]))
        when "PReLU"
          constant.new(num_parameters: 1).forward(Torch.tensor([ [ -1.0, 1.0 ] ]))
        when "ReLU", "ELU", "GELU", "LeakyReLU", "Softplus", "Softsign", "Sigmoid", "Tanh", "Tanhshrink", "Hardshrink", "Softshrink", "LogSigmoid", "Identity"
          constant.new.forward(Torch.tensor([ [ -1.0, 1.0 ] ]))
        when "Softmax", "Softmin", "LogSoftmax"
          constant.new(dim: 1).forward(Torch.tensor([ [ 1.0, 2.0 ], [ 2.0, 1.0 ] ]))
        when "ConstantPad1d", "ReflectionPad1d", "ReplicationPad1d"
          padding_module(constant, short_name, 1)
        when "ConstantPad2d", "ReflectionPad2d", "ReplicationPad2d", "ZeroPad2d"
          padding_module(constant, short_name, 2)
        when "ConstantPad3d", "ReplicationPad3d"
          padding_module(constant, short_name, 3)
        when "Fold"
          constant.new([ 3, 3 ], [ 2, 2 ]).forward(Torch.tensor([ [ [ 1.0, 2.0, 3.0, 4.0 ], [ 5.0, 6.0, 7.0, 8.0 ], [ 9.0, 10.0, 11.0, 12.0 ], [ 13.0, 14.0, 15.0, 16.0 ] ] ]))
        when "Unfold"
          constant.new([ 2, 2 ]).forward(Torch.ones([ 1, 1, 3, 3 ]))
        when "Sequential"
          constant.new(Torch::NN::ReLU.new, Torch::NN::Sigmoid.new).forward(Torch.tensor([ [ -1.0, 1.0 ] ]))
        else
          return inspection_result(constant, "#{short_name} foi resolvido; sua assinatura não possui um fixture padrão seguro nesta versão.")
        end

        values = numeric_values(value)
        result(
          title: "#{human_api_name} executado",
          equation: value.inspect,
          stats: [
            { label: "Valores", value: values.length.to_s },
            { label: "API", value: short_api_name },
            { label: "Dispositivo", value: "CPU" }
          ],
          note: "O módulo foi instanciado com dimensões pequenas e recebeu um tensor compatível com sua operação.",
          source: "layer = #{experiment.api_name}.new(...)\nlayer.forward(input)",
          chart: bar_chart(labels: (1..[ values.length, 12 ].min).to_a, values: values.first(12))
        )
      end

      def sequence_tensor
        Torch.tensor([ [ [ 1.0, 0.0 ], [ 0.0, 1.0 ] ] ])
      end

      def extract_primary(value)
        value.is_a?(Array) ? value.first : value
      end

      def unpool_with_indices(constant, dimensions, values)
        input = Torch.tensor(values)
        pool_name = "MaxPool#{dimensions}d"
        pool = Torch::NN.const_get(pool_name).new(dimensions == 1 ? 2 : Array.new(dimensions, 2), return_indices: true)
        pooled, indices = pool.forward(input)
        constant.new(dimensions == 1 ? 2 : Array.new(dimensions, 2)).forward(pooled, indices)
      end

      def padding_module(constant, short_name, dimensions)
        input = case dimensions
        when 1 then Torch.tensor([ [ [ 1.0, 2.0, 3.0 ] ] ])
        when 2 then Torch.tensor([ [ [ [ 1.0, 2.0 ], [ 3.0, 4.0 ] ] ] ])
        else Torch.ones([ 1, 1, 2, 2, 2 ])
        end
        padding = Array.new(dimensions * 2, 1)
        module_instance = if short_name.start_with?("Constant")
          constant.new(padding, 0.0)
        elsif short_name == "ZeroPad2d"
          constant.new(padding)
        else
          constant.new(padding)
        end
        module_instance.forward(input)
      end

      def run_linear(constant)
        model = constant.new(2, 1)
        input = Torch.tensor([ [ 1.0, 2.0 ], [ 2.0, 1.0 ] ])
        output = model.forward(input)

        result(
          title: "Rede linear executada",
          equation: output.inspect,
          stats: [
            { label: "Entradas", value: "2" },
            { label: "Saídas", value: "1" },
            { label: "API", value: short_api_name }
          ],
          note: "Uma camada Linear transforma duas características em uma saída por amostra.",
          source: "layer = Torch::NN::Linear.new(2, 1)\nlayer.forward(input)",
          chart: line_chart(labels: [ "a", "b" ], series: [ { label: "saída", data: numeric_values(output) } ])
        )
      end

      def run_loss(constant)
        loss = constant.new
        input, target = classification_loss_inputs
        value = loss.forward(input, target)

        result(
          title: "#{human_api_name} calculada",
          equation: value.inspect,
          stats: [
            { label: "Perda", value: format_value(value) },
            { label: "Amostras", value: "2" },
            { label: "API", value: short_api_name }
          ],
          note: "A função de perda compara uma previsão pequena com seu alvo correspondente.",
          source: "loss = #{experiment.api_name}.new\nloss.forward(prediction, target)",
          chart: bar_chart(labels: [ "perda" ], values: [ value ])
        )
      end

      def run_special_loss(constant, short_name)
        return unavailable_result("O construtor de MultiLabelSoftMarginLoss da versão instalada chama WeightedLoss com uma assinatura incompatível; a função funcional também não está implementada no binding.") if short_name == "MultiLabelSoftMarginLoss"
        return inspection_result(constant, "WeightedLoss é uma classe base para perdas ponderadas; use uma perda concreta para executar o forward.") if short_name == "WeightedLoss"

        value = case short_name
        when "CTCLoss"
          log_probs = Torch.randn([ 3, 1, 3 ]).log_softmax(2)
          constant.new.forward(log_probs, Torch.tensor([ 1, 2 ], dtype: Torch.int64), Torch.tensor([ 3 ], dtype: Torch.int64), Torch.tensor([ 2 ], dtype: Torch.int64))
        when "CosineEmbeddingLoss"
          constant.new.forward(Torch.tensor([ [ 1.0, 0.0 ], [ 0.0, 1.0 ] ]), Torch.tensor([ [ 0.8, 0.1 ], [ 0.1, 0.8 ] ]), Torch.tensor([ 1, 1 ], dtype: Torch.int64))
        when "MarginRankingLoss"
          constant.new.forward(Torch.tensor([ 2.0, 1.0 ]), Torch.tensor([ 1.0, 2.0 ]), Torch.tensor([ 1, -1 ], dtype: Torch.int64))
        when "MultiLabelMarginLoss"
          constant.new.forward(Torch.tensor([ [ 2.0, 0.1, -1.0 ], [ 0.1, 2.0, -1.0 ] ]), Torch.tensor([ [ 0, -1, -1 ], [ 1, -1, -1 ] ], dtype: Torch.int64))
        when "MultiMarginLoss"
          constant.new.forward(Torch.tensor([ [ 2.0, 0.1, 0.2 ], [ 0.1, 2.0, 0.2 ] ]), Torch.tensor([ 0, 1 ], dtype: Torch.int64))
        when "MultiLabelSoftMarginLoss"
          constant.new.forward(Torch.tensor([ [ 2.0, -1.0 ], [ -1.0, 2.0 ] ]), Torch.tensor([ [ 1.0, 0.0 ], [ 0.0, 1.0 ] ]))
        when "TripletMarginLoss"
          constant.new.forward(Torch.tensor([ [ 1.0, 0.0 ], [ 0.0, 1.0 ] ]), Torch.tensor([ [ 0.8, 0.1 ], [ 0.1, 0.8 ] ]), Torch.tensor([ [ -1.0, 0.0 ], [ 0.0, -1.0 ] ]))
        end

        result(
          title: "#{human_api_name} calculada",
          equation: value.inspect,
          stats: [
            { label: "Perda", value: format_value(value) },
            { label: "API", value: short_api_name },
            { label: "Dispositivo", value: "CPU" }
          ],
          note: "A perda recebeu tensores com as formas exigidas pela assinatura da API.",
          source: "loss = #{experiment.api_name}.new\nloss.forward(...) ",
          chart: bar_chart(labels: [ "perda" ], values: [ value ])
        )
      end

      def classification_loss_inputs
        if experiment.api_name.end_with?("CrossEntropyLoss")
          return Torch.tensor([ [ 2.0, 0.1 ], [ 0.1, 2.0 ] ]), Torch.tensor([ 0, 1 ], dtype: Torch.int64)
        end

        if experiment.api_name.end_with?("NLLLoss")
          return Torch.tensor([ [ 0.0, -2.0 ], [ -2.0, 0.0 ] ]), Torch.tensor([ 0, 1 ], dtype: Torch.int64)
        end

        [ Torch.tensor([ [ 0.2 ], [ 0.8 ] ]), Torch.tensor([ [ 0.0 ], [ 1.0 ] ]) ]
      end

      def run_similarity(constant)
        input1 = Torch.tensor([ [ 1.0, 0.0 ], [ 0.0, 1.0 ] ])
        input2 = Torch.tensor([ [ 0.8, 0.1 ], [ 0.1, 0.8 ] ])
        value = if experiment.api_name.end_with?("CosineSimilarity")
          constant.new.forward(input1, input2)
        else
          constant.new.forward(input1, input2)
        end

        result(
          title: "#{human_api_name} calculada",
          equation: value.inspect,
          stats: [
            { label: "Pares", value: "2" },
            { label: "API", value: short_api_name },
            { label: "Dispositivo", value: "CPU" }
          ],
          note: "A medida foi aplicada a dois pares de vetores reais.",
          source: "metric = #{experiment.api_name}.new\nmetric.forward(input1, input2)",
          chart: bar_chart(labels: [ "par 1", "par 2" ], values: numeric_values(value))
        )
      end

      def run_transformer(constant)
        model = constant.new(d_model: 2, nhead: 1, num_encoder_layers: 1, num_decoder_layers: 1, batch_first: true)
        source = Torch.tensor([ [ [ 1.0, 0.0 ], [ 0.0, 1.0 ] ] ])
        output = model.forward(source, source)

        result(
          title: "#{human_api_name} executado",
          equation: output.inspect,
          stats: [
            { label: "Sequência", value: "2" },
            { label: "Dimensão", value: "2" },
            { label: "API", value: short_api_name }
          ],
          note: "O Transformer recebeu uma sequência fonte e um alvo com batch_first habilitado.",
          source: "model = Torch::NN::Transformer.new(d_model: 2, nhead: 1, batch_first: true)\nmodel.forward(src, tgt)",
          chart: line_chart(labels: [ "t1", "t2" ], series: [ { label: "saída", data: numeric_values(output).first(2) } ])
        )
      end

      def run_softmax_2d(constant)
        input = Torch.tensor([ [ [ [ 1.0, 2.0 ], [ 3.0, 4.0 ] ] ] ])
        output = constant.new.forward(input)

        result(
          title: "#{human_api_name} executado",
          equation: output.inspect,
          stats: [
            { label: "Dimensão", value: "1 × 1 × 2 × 2" },
            { label: "API", value: short_api_name },
            { label: "Dispositivo", value: "CPU" }
          ],
          note: "A camada recebeu um tensor 4D, como exige a API Softmax2d.",
          source: "layer = Torch::NN::Softmax2d.new\nlayer.forward(input)",
          chart: bar_chart(labels: [ "p1", "p2", "p3", "p4" ], values: numeric_values(output))
        )
      end

      def run_upsample(constant)
        input = Torch.tensor([ [ [ [ 1.0, 2.0 ], [ 3.0, 4.0 ] ] ] ])
        output = constant.new(size: [ 4, 4 ], mode: "nearest").forward(input)

        result(
          title: "#{human_api_name} executado",
          equation: output.inspect,
          stats: [
            { label: "Entrada", value: "2 × 2" },
            { label: "Saída", value: "4 × 4" },
            { label: "API", value: short_api_name }
          ],
          note: "A camada ampliou uma imagem 2D por interpolação nearest.",
          source: "layer = Torch::NN::Upsample.new(size: [4, 4], mode: \"nearest\")\nlayer.forward(input)",
          chart: bar_chart(labels: [ "min", "max" ], values: [ numeric_values(output).min, numeric_values(output).max ])
        )
      end

      def run_optimizer
        constant = resolve_constant(experiment.api_name)
        model = Torch::NN::Linear.new(1, 1)
        optimizer = constant.new(model.parameters, lr: 0.05)
        optimizer.zero_grad if optimizer.respond_to?(:zero_grad)
        prediction = model.forward(Torch.tensor([ [ 1.0 ], [ 2.0 ] ]))
        target = Torch.tensor([ [ 2.0 ], [ 4.0 ] ])
        loss = Torch::NN::MSELoss.new.forward(prediction, target)
        loss.backward
        optimizer.step

        result(
          title: "#{human_api_name} atualizou os pesos",
          equation: "loss = #{format_value(loss)}",
          stats: [
            { label: "Amostras", value: "2" },
            { label: "Taxa", value: "0.05" },
            { label: "API", value: short_api_name }
          ],
          note: "O otimizador executou uma etapa depois do backward de uma camada linear.",
          source: "optimizer = #{experiment.api_name}.new(model.parameters, lr: 0.05)\noptimizer.step",
          chart: bar_chart(labels: [ "loss" ], values: [ loss ])
        )
      end

      def run_distribution
        constant = resolve_constant(experiment.api_name)
        distribution = if experiment.api_name.end_with?("Normal")
          constant.new(Torch.tensor(0.0), Torch.tensor(1.0))
        else
          return inspection_result(constant, "A distribuição base foi resolvida; escolha uma distribuição concreta para amostrar.")
        end
        sample = distribution.sample

        result(
          title: "#{human_api_name} amostrada",
          equation: sample.inspect,
          stats: [
            { label: "Amostra", value: format_value(sample) },
            { label: "API", value: short_api_name },
            { label: "Dispositivo", value: "CPU" }
          ],
          note: "Uma amostra foi extraída da distribuição para tornar o conceito observável.",
          source: "distribution = #{experiment.api_name}.new(0.0, 1.0)\ndistribution.sample",
          chart: bar_chart(labels: [ "amostra" ], values: [ sample ])
        )
      end

      def run_data
        constant = resolve_constant(experiment.api_name)
        if experiment.api_name.end_with?("TensorDataset")
          dataset = constant.new(Torch.tensor([ [ 1.0 ], [ 2.0 ] ]), Torch.tensor([ 0, 1 ]))
          sample = dataset[0]
          return result(
            title: "Dataset indexado",
            equation: sample.inspect,
            stats: [
              { label: "Tamanho", value: dataset.length.to_s },
              { label: "Índice", value: "0" },
              { label: "API", value: short_api_name }
            ],
            note: "O dataset foi criado a partir de tensores e consultado por índice.",
            source: "dataset = Torch::Utils::Data::TensorDataset.new(features, targets)\ndataset[0]",
            chart: bar_chart(labels: [ "feature", "target" ], values: numeric_values(sample))
          )
        end

        if experiment.api_name.end_with?("DataLoader")
          dataset = Torch::Utils::Data::TensorDataset.new(Torch.tensor([ [ 1.0 ], [ 2.0 ] ]), Torch.tensor([ 0, 1 ]))
          loader = constant.new(dataset, batch_size: 1, shuffle: false)
          batch = loader.each.first
          values = numeric_values(batch)
          return result(
            title: "DataLoader iterado",
            equation: batch.inspect,
            stats: [
              { label: "Batch", value: values.length.to_s },
              { label: "Tamanho", value: loader.length.to_s },
              { label: "API", value: short_api_name }
            ],
            note: "O DataLoader criou um batch real a partir de um TensorDataset.",
            source: "loader = Torch::Utils::Data::DataLoader.new(dataset, batch_size: 1)\nloader.each.first",
            chart: bar_chart(labels: (1..[ values.length, 8 ].min).to_a, values: values.first(8))
          )
        end

        if experiment.api_name.end_with?("Subset")
          dataset = Torch::Utils::Data::TensorDataset.new(Torch.tensor([ [ 1.0 ], [ 2.0 ] ]), Torch.tensor([ 0, 1 ]))
          subset = constant.new(dataset, [ 1 ])
          sample = subset[0]
          values = numeric_values(sample)
          return result(
            title: "Subset indexado",
            equation: sample.inspect,
            stats: [
              { label: "Tamanho", value: subset.length.to_s },
              { label: "Índice original", value: "1" },
              { label: "API", value: short_api_name }
            ],
            note: "O subconjunto apontou para uma amostra real do TensorDataset.",
            source: "subset = Torch::Utils::Data::Subset.new(dataset, [1])\nsubset[0]",
            chart: bar_chart(labels: (1..values.length).to_a, values: values)
          )
        end

        inspection_result(constant, "Esta API pertence ao pipeline de dados; a página identifica seu contrato para composição com um DataLoader.")
      end

      def run_init
        parameter = Torch::NN::Parameter.new(Torch.tensor([ 1.0, -1.0 ]))
        Torch::NN::Init.zeros!(parameter)
        values = numeric_values(parameter)

        result(
          title: "Inicialização de pesos executada",
          equation: parameter.inspect,
          stats: [
            { label: "Elementos", value: values.length.to_s },
            { label: "Estratégia", value: "zeros!" },
            { label: "API", value: "Torch::NN::Init" }
          ],
          note: "A função de inicialização alterou um Parameter real do Torch.rb.",
          source: "parameter = Torch::NN::Parameter.new(Torch.tensor([1.0, -1.0]))\nTorch::NN::Init.zeros!(parameter)",
          chart: bar_chart(labels: [ "p1", "p2" ], values: values)
        )
      end

      def instantiate_module(constant, short_name)
        return constant.new if %w[ReLU ELU GELU LeakyReLU PReLU Softplus Softsign Sigmoid Tanh Identity].include?(short_name)
        return constant.new if %w[MSELoss L1Loss SmoothL1Loss BCELoss BCEWithLogitsLoss CrossEntropyLoss NLLLoss].include?(short_name)

        constant.new
      rescue ArgumentError, TypeError, NoMethodError
        nil
      end

      def torch_function_call(name)
        case name
        when "zeros" then Torch.zeros([ 2, 2 ])
        when "ones" then Torch.ones([ 2, 2 ])
        when "empty" then Torch.empty([ 2, 2 ])
        when "full" then Torch.full([ 2, 2 ], 3.0)
        when "eye" then Torch.eye(2)
        when "arange" then Torch.arange(0, 5)
        when "linspace" then Torch.linspace(0.0, 1.0, 5)
        when "logspace" then Torch.logspace(0.0, 1.0, 5)
        when "rand" then Torch.rand([ 2, 2 ])
        when "randn" then Torch.randn([ 2, 2 ])
        when "randint" then Torch.randint(0, 3, [ 2, 2 ])
        when "randperm" then Torch.randperm(5)
        when "argmax" then Torch.argmax(Torch.tensor([ 1.0, 3.0, 2.0 ]))
        when "argmin" then Torch.argmin(Torch.tensor([ 1.0, 3.0, 2.0 ]))
        when "manual_seed" then Torch.manual_seed(7)
        else Torch.public_send(name)
        end
      end

      def tensor_values
        values = params[:values] || params["values"]
        parsed = values.to_s.split(",").filter_map do |value|
          Float(value.strip)
        rescue ArgumentError, TypeError
          nil
        end

        parsed.first(12).presence || DEFAULT_TENSOR_VALUES
      end
    end
  end
end
