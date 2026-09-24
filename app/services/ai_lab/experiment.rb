module AiLab
  Experiment = Struct.new(
    :slug, :title, :library, :status, :summary, :description, :accent, :steps,
    keyword_init: true
  ) do
    def available?
      status == :available
    end
  end
end
