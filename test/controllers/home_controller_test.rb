require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "home lists every experiment in the catalog" do
    get root_path

    assert_response :success
    assert_select "h1", /Aprender IA/
    assert_select ".experiment-card", count: AiLab::ExperimentCatalog.all.length
    assert_select "a[href=?]", experiment_path("regressao-linear")
    assert_select "a[href=?]", experiment_path("tensores")
  end
end
