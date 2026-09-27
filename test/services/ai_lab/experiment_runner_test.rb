require "test_helper"

class AiLab::ExperimentRunnerTest < ActiveSupport::TestCase
  test "unknown or unavailable experiments return a preparation result" do
    experiment = AiLab::ExperimentCatalog.find("rumale-nearest-neighbors-nearest-neighbors")

    result = AiLab::ExperimentRunner.call(experiment)

    assert_equal :incompatible, result[:kind]
    assert_equal "API não disponível nesta versão", result[:title]
  end

  test "runs one adapter from each library" do
    rumale = AiLab::ExperimentRunner.call(AiLab::ExperimentCatalog.find("rumale-linear-model-ridge"))
    torch = AiLab::ExperimentRunner.call(AiLab::ExperimentCatalog.find("torch-nn-mseloss"))

    assert_equal :result, rumale[:kind]
    assert_equal :result, torch[:kind]
    assert rumale[:source].include?("Ridge")
    assert torch[:source].include?("MSELoss")
  end

  test "every executed experiment exposes a chart from its algorithm output" do
    results = AiLab::ExperimentCatalog.all.map do |experiment|
      [ experiment, AiLab::ExperimentRunner.call(experiment) ]
    end

    executed = results.select { |_experiment, result| result[:mode] == :executed }
    fallback = results.select { |_experiment, result| result[:mode] == :needs_parameters }

    assert_equal 236, executed.length
    assert_empty fallback
    assert executed.all? { |_experiment, result| result[:chart].present? }
    assert_equal 36, results.count { |_experiment, result| result[:mode] == :unavailable }
    assert_equal 28, results.count { |_experiment, result| result[:mode] == :inspection }
  end
end
