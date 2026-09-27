module AiLab
  module Experiments
    class Base
      attr_reader :experiment, :params

      def self.call(experiment, params = {})
        new(experiment, params).call
      end

      def initialize(experiment, params)
        @experiment = experiment
        @params = params
      end

      private

      def result(title:, equation:, stats:, note:, source:, chart: nil, mode: :executed)
        {
          kind: :result,
          mode: mode,
          title: title,
          equation: equation,
          stats: stats,
          note: note,
          source: source,
          chart: chart
        }
      end

      def inspection_result(constant, note = nil)
        result(
          title: "#{human_api_name} catalogada",
          equation: constant ? constant.name.to_s : short_api_name,
          stats: [
            { label: "API", value: short_api_name },
            { label: "Biblioteca", value: experiment.library },
            { label: "Categoria", value: experiment.category.to_s }
          ],
          note: note || "A entrada está disponível na versão instalada e foi registrada individualmente.",
          source: "#{experiment.api_name || experiment.title}\n# consulte a assinatura desta API",
          mode: :inspection
        )
      end

      def execution_result(title, note)
        result(
          title: title,
          equation: short_api_name,
          stats: [
            { label: "API", value: short_api_name },
            { label: "Estado", value: "requer parâmetros" },
            { label: "Biblioteca", value: experiment.library }
          ],
          note: note,
          source: "#{experiment.api_name || experiment.title}\n# adapte os parâmetros ao seu dataset",
          mode: :needs_parameters
        )
      end

      def unavailable_result(note)
        {
          kind: :unavailable,
          mode: :unavailable,
          title: "API indisponível nesta instalação",
          equation: experiment.api_name.to_s,
          stats: [
            { label: "API", value: short_api_name },
            { label: "Estado", value: "não disponível" },
            { label: "Biblioteca", value: experiment.library }
          ],
          note: note,
          source: "#{experiment.api_name}\n# verifique a versão do torch-rb instalada"
        }
      end

      def resolve_constant(path)
        path.split("::").reject(&:empty?).inject(Object) do |scope, part|
          raise UnavailableApiError, "#{path} não está disponível" unless scope.const_defined?(part, false)

          scope.const_get(part, false)
        end
      end

      def human_api_name
        experiment.title
      end

      def short_api_name
        experiment.api_name.to_s.split("::").last.to_s.split(".").last.presence || experiment.title
      end

      def flat_values(value)
        return value.flat_map { |item| flat_values(item) } if value.is_a?(Array)
        return flat_values(value.to_a) if value.respond_to?(:to_a)

        [ value ]
      end

      def numeric_values(value)
        flat_values(value).filter_map do |item|
          Float(item)
        rescue ArgumentError, TypeError
          nil
        end
      end

      def format_value(value)
        number = value.respond_to?(:item) ? value.item : value
        number = number.to_f if number.respond_to?(:to_f)
        number.is_a?(Float) ? format("%.4f", number) : number.to_s
      end

      def line_chart(labels:, series:)
        {
          type: "line",
          labels: labels.map(&:to_s),
          series: series.map { |item| { label: item[:label], data: item[:data].map(&:to_f) } }
        }
      end

      def bar_chart(labels:, values:)
        {
          type: "bar",
          labels: labels.map(&:to_s),
          series: [ { label: "resultado", data: values.map(&:to_f) } ]
        }
      end

      def scatter_chart(points:, groups: nil)
        {
          type: "scatter",
          points: points.map { |x, y, index| { x: x.to_f, y: y.to_f, group: groups ? groups[index].to_i : 0 } }
        }
      end
    end
  end
end
