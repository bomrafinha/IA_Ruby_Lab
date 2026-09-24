class HomeController < ApplicationController
  def index
    @experiments = AiLab::ExperimentCatalog.all
  end
end
