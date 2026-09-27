module AiLab
  Experiment = Struct.new(
    :slug, :title, :library, :status, :summary, :description, :accent, :steps,
    :api_name, :namespace, :category,
    keyword_init: true
  ) do
    def available?
      status == :available
    end

    def incompatible?
      status == :incompatible
    end
  end
end
