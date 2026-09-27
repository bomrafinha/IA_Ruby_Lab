require "test_helper"

class ExperimentsControllerTest < ActionDispatch::IntegrationTest
  test "linear regression experiment runs Rumale" do
    post run_experiment_path("regressao-linear"), params: { sample: "8" }

    assert_response :success
    assert_select ".result-block"
    assert_includes response.body, "17.00"
  end

  test "tensor experiment runs Torch.rb" do
    post run_experiment_path("tensores"), params: { values: "1, 3, 5" }

    assert_response :success
    assert_select ".result-block"
    assert_includes response.body, "3.00"
  end

  test "incompatible experiment has a compatibility page" do
    get experiment_path("rumale-nearest-neighbors-nearest-neighbors")

    assert_response :success
    assert_select ".coming-soon"
  end
end
