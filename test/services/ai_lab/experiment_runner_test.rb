require "test_helper"

class AiLab::ExperimentRunnerTest < ActiveSupport::TestCase
  test "unknown or unavailable experiments return a preparation result" do
    experiment = AiLab::ExperimentCatalog.find("rede-neural")

    result = AiLab::ExperimentRunner.call(experiment)

    assert_equal :soon, result[:kind]
    assert_equal "Aula em preparação", result[:title]
  end
end
