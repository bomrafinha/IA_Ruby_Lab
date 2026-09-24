class ExperimentsController < ApplicationController
  before_action :set_experiment

  def show
    @result = AiLab::ExperimentRunner.call(@experiment)
  end

  def run
    @result = AiLab::ExperimentRunner.call(@experiment, experiment_params)
    render :show
  end

  private

  def set_experiment
    @experiment = AiLab::ExperimentCatalog.find(params[:slug])
    raise ActionController::RoutingError, "Experiment not found" unless @experiment
  end

  def experiment_params
    params.permit(:sample, :values)
  end
end
