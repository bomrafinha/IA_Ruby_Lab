module AiLab
  class ExperimentExecutor
    def self.call(experiment, params = {})
      new(experiment, params).call
    end

    def initialize(experiment, params)
      @experiment = experiment
      @params = params
    end

    def call
      return not_found_result unless @experiment
      return incompatible_result unless @experiment.available?

      adapter_class.call(@experiment, @params)
    rescue LoadError => error
      execution_result("Dependência indisponível", error.message)
    rescue AiLab::Experiments::UnavailableApiError => error
      unavailable_result(error.message)
    rescue StandardError => error
      return unavailable_result(error.message) if error.message.include?("Numo::Linalg")

      execution_result(
        "API registrada",
        "A API foi encontrada, mas o fixture desta aula precisa de parâmetros específicos: #{error.message}"
      )
    end

    private

    def adapter_class
      case @experiment.library
      when "Rumale"
        AiLab::Experiments::RumaleAdapter
      when "Torch.rb"
        AiLab::Experiments::TorchAdapter
      else
        raise NameError, "Biblioteca não reconhecida: #{@experiment.library}"
      end
    end

    def not_found_result
      {
        kind: :not_found,
        mode: :not_found,
        title: "Experimento não encontrado",
        note: "A rota solicitada não pertence ao catálogo."
      }
    end

    def incompatible_result
      {
        kind: :incompatible,
        mode: :incompatible,
        title: "API não disponível nesta versão",
        note: "#{@experiment.api_name} aparece no inventário, mas não está exposta pela versão instalada da gem.",
        source: "Gem instalada: rumale 2.2.0"
      }
    end

    def execution_result(title, note)
      {
        kind: :result,
        title: title,
        equation: @experiment.api_name.to_s,
        stats: [
          { label: "API", value: @experiment.api_name.to_s.split("::").last },
          { label: "Estado", value: "requer parâmetros" },
          { label: "Biblioteca", value: @experiment.library }
        ],
        note: note,
        source: "#{@experiment.api_name || @experiment.title}\n# adapte os parâmetros ao seu dataset",
        mode: :needs_parameters
      }
    end

    def unavailable_result(note)
      {
        kind: :unavailable,
        mode: :unavailable,
        title: "API indisponível nesta instalação",
        equation: @experiment.api_name.to_s,
        stats: [
          { label: "API", value: @experiment.api_name.to_s.split("::").last },
          { label: "Estado", value: "não disponível" },
          { label: "Biblioteca", value: @experiment.library }
        ],
        note: note,
        source: "#{@experiment.api_name}\n# verifique a versão e as dependências da gem"
      }
    end
  end
end
