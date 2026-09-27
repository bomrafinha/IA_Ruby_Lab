require "test_helper"

class AiLab::ExperimentCatalogTest < ActiveSupport::TestCase
  test "catalogs every documented API with a unique slug" do
    experiments = AiLab::ExperimentCatalog.all

    assert_equal 301, experiments.length
    assert_equal experiments.length, experiments.map(&:slug).uniq.length
    assert_equal 126, experiments.count { |experiment| experiment.library == "Rumale" }
    assert_equal 175, experiments.count { |experiment| experiment.library == "Torch.rb" }
  end

  test "keeps legacy routes and the known incompatible API" do
    %w[regressao-linear tensores classificacao-knn rede-neural].each do |slug|
      assert AiLab::ExperimentCatalog.find(slug).available?
    end

    incompatible = AiLab::ExperimentCatalog.find("rumale-nearest-neighbors-nearest-neighbors")
    assert incompatible.incompatible?
    assert_equal "Rumale::NearestNeighbors::NearestNeighbors", incompatible.api_name
  end
end
