module AiLab
  class ExperimentRunner
    def self.call(experiment, params = {})
      new(experiment, params).call
    end

    def initialize(experiment, params)
      @experiment = experiment
      @params = params
    end

    def call
      AiLab::ExperimentExecutor.call(@experiment, @params)
    end
  end
end
