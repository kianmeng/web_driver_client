defmodule WebDriverClient.Integration.VisitingPagesTest do
  use ExUnit.Case, async: false

  alias WebDriverClient.IntegrationTesting.Scenarios
  alias WebDriverClient.IntegrationTesting.TestGenerator
  alias WebDriverClient.IntegrationTesting.TestServer
  alias WebDriverClient.Session

  require WebDriverClient.IntegrationTesting.TestGenerator

  @moduletag :capture_log
  @moduletag :integration

  TestGenerator.generate_describe_per_scenario do
    test "visiting a page", %{scenario: scenario} do
      config = Scenarios.get_config(scenario)
      payload = Scenarios.get_start_session_payload(scenario)

      {:ok, session} = WebDriverClient.start_session(payload, config: config)

      ensure_session_is_closed(session)

      url = TestServer.get_base_url()

      :ok = WebDriverClient.navigate_to(session, url)

      assert {:ok, returned_url} = WebDriverClient.fetch_current_url(session)
      assert String.starts_with?(returned_url, url)
    end
  end

  @spec ensure_session_is_closed(Session.t()) :: :ok
  defp ensure_session_is_closed(%Session{} = session) do
    on_exit(fn ->
      :ok = WebDriverClient.end_session(session)
    end)
  end
end