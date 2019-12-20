defmodule WebDriverClientTest do
  use WebDriverClient.APIClientCase, async: true
  use ExUnitProperties

  import Plug.Conn
  import WebDriverClient.ErrorScenarios

  alias WebDriverClient.Element
  alias WebDriverClient.JSONWireProtocolClient.TestResponses, as: JWPTestResponses
  alias WebDriverClient.LogEntry
  alias WebDriverClient.Session
  alias WebDriverClient.Size
  alias WebDriverClient.TestData
  alias WebDriverClient.W3CWireProtocolClient.TestResponses, as: W3CTestResponses

  @moduletag :bypass
  @moduletag :capture_log

  @protocols [:jwp, :w3c]

  @tag protocol: :jwp
  test "start_session/2 with JWP config returns {:ok, Session.t()} with a valid response", %{
    config: config,
    bypass: bypass
  } do
    resp = JWPTestResponses.start_session_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert {:ok, %Session{config: ^config}} =
             WebDriverClient.start_session(build_start_session_payload(), config: config)
  end

  @tag protocol: :w3c
  test "start_session/2 with W3C config returns {:ok, Session.t()} with a valid response", %{
    config: config,
    bypass: bypass
  } do
    resp = W3CTestResponses.start_session_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert {:ok, %Session{config: ^config}} =
             WebDriverClient.start_session(build_start_session_payload(), config: config)
  end

  for protocol <- @protocols do
    @tag protocol: protocol
    test "start_session/2 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass} do
      scenario_server = set_up_error_scenario_tests(bypass)

      for error_scenario <- basic_error_scenarios() do
        %Session{config: config} =
          build_session_for_scenario(scenario_server, bypass, config, error_scenario)

        assert_expected_response(
          WebDriverClient.start_session(build_start_session_payload(), config: config),
          error_scenario
        )
      end
    end
  end

  @tag protocol: :jwp
  test "fetch_sessions/1 with jwp session returns {:ok, %Session{}] on success", %{
    config: config,
    bypass: bypass
  } do
    resp = JWPTestResponses.fetch_sessions_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert {:ok, sessions} = WebDriverClient.fetch_sessions(config: config)
    assert Enum.all?(sessions, &match?(%Session{config: ^config}, &1))
  end

  @tag protocol: :w3c
  test "fetch_sessions/1 with w3c session returns {:ok, %Session{}] on success", %{
    config: config,
    bypass: bypass
  } do
    resp = W3CTestResponses.fetch_sessions_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert {:ok, sessions} = WebDriverClient.fetch_sessions(config: config)
    assert Enum.all?(sessions, &match?(%Session{config: ^config}, &1))
  end

  for protocol <- @protocols do
    @tag protocol: protocol
    test "fetch_sessions/1 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass} do
      scenario_server = set_up_error_scenario_tests(bypass)

      for error_scenario <- basic_error_scenarios() do
        %Session{config: config} =
          build_session_for_scenario(scenario_server, bypass, config, error_scenario)

        assert_expected_response(
          WebDriverClient.fetch_sessions(config: config),
          error_scenario
        )
      end
    end
  end

  @tag protocol: :jwp
  test "end_session/1 with jwp session returns :ok on success", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = JWPTestResponses.end_session_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert :ok = WebDriverClient.end_session(session)
  end

  @tag protocol: :w3c
  test "end_session/1 with w3c session returns :ok on success", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = W3CTestResponses.end_session_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert :ok = WebDriverClient.end_session(session)
  end

  for protocol <- @protocols do
    @tag protocol: protocol
    test "end_session/1 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass} do
      scenario_server = set_up_error_scenario_tests(bypass)

      for error_scenario <- basic_error_scenarios() do
        session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)

        assert_expected_response(
          WebDriverClient.end_session(session),
          error_scenario
        )
      end
    end
  end

  @tag protocol: :jwp
  test "navigate_to/2 with jwp session returns {:ok, url} on success", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = JWPTestResponses.navigate_to_response() |> pick()
    browser_url = "http://foo.bar.example"

    stub_bypass_response(bypass, resp)

    assert :ok = WebDriverClient.navigate_to(session, browser_url)
  end

  @tag protocol: :w3c
  test "navigate_to/2 with w3c session returns {:ok, url} on success", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = W3CTestResponses.navigate_to_response() |> pick()
    browser_url = "http://foo.bar.example"

    stub_bypass_response(bypass, resp)

    assert :ok = WebDriverClient.navigate_to(session, browser_url)
  end

  for protocol <- @protocols do
    @tag protocol: protocol
    test "navigate_to/2 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass} do
      scenario_server = set_up_error_scenario_tests(bypass)

      for error_scenario <- basic_error_scenarios() do
        session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)

        assert_expected_response(
          WebDriverClient.navigate_to(session, "http://foo.com"),
          error_scenario
        )
      end
    end
  end

  @tag protocol: :w3c
  test "fetch_current_url/1 with w3c session returns {:ok, url} on success", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = W3CTestResponses.fetch_current_url_response() |> pick()
    stub_bypass_response(bypass, resp)

    assert {:ok, url} = WebDriverClient.fetch_current_url(session)
    assert is_binary(url)
  end

  @tag protocol: :jwp
  test "fetch_current_url/1 with JWP session returns {:ok, url} on success", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = JWPTestResponses.fetch_current_url_response() |> pick()
    stub_bypass_response(bypass, resp)

    assert {:ok, url} = WebDriverClient.fetch_current_url(session)
    assert is_binary(url)
  end

  for protocol <- @protocols do
    @tag protocol: protocol
    test "fetch_current_url/1 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass} do
      scenario_server = set_up_error_scenario_tests(bypass)

      for error_scenario <- basic_error_scenarios() do
        session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)

        assert_expected_response(
          WebDriverClient.fetch_current_url(session),
          error_scenario
        )
      end
    end
  end

  @tag protocol: :jwp
  test "fetch_window_size/1 with JWP session returns {:ok, %Size{}} on success", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = JWPTestResponses.fetch_window_size_response() |> pick()
    stub_bypass_response(bypass, resp)

    assert {:ok, %Size{}} = WebDriverClient.fetch_window_size(session)
  end

  @tag protocol: :w3c
  test "fetch_window_size/1 with w3c session returns {:ok, %Size{}} on success", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = W3CTestResponses.fetch_window_rect_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert {:ok, %Size{}} = WebDriverClient.fetch_window_size(session)
  end

  for protocol <- @protocols do
    @tag protocol: protocol
    test "fetch_window_size/1 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass} do
      scenario_server = set_up_error_scenario_tests(bypass)

      for error_scenario <- basic_error_scenarios() do
        session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)

        assert_expected_response(
          WebDriverClient.fetch_window_size(session),
          error_scenario
        )
      end
    end
  end

  @tag protocol: :jwp
  test "set_window_size/2 with JWP session returns :ok on valid response", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = JWPTestResponses.set_window_size_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert :ok = WebDriverClient.set_window_size(session)
  end

  @tag protocol: :w3c
  test "set_window_size/2 with w3c session returns :ok on valid response", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = W3CTestResponses.set_window_rect_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert :ok = WebDriverClient.set_window_size(session)
  end

  for protocol <- @protocols do
    @tag protocol: protocol
    test "set_window_size/1 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass} do
      scenario_server = set_up_error_scenario_tests(bypass)

      for error_scenario <- basic_error_scenarios() do
        session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)

        assert_expected_response(
          WebDriverClient.set_window_size(session),
          error_scenario
        )
      end
    end
  end

  @tag protocol: :jwp
  test "fetch_log_types/1 with JWP session returns {:ok, types} on valid response", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = JWPTestResponses.fetch_log_types_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert {:ok, log_types} = WebDriverClient.fetch_log_types(session)
    assert Enum.all?(log_types, &is_binary/1)
  end

  @tag protocol: :w3c
  test "fetch_log_types/1 with w3c session returns :ok on valid response", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = W3CTestResponses.fetch_log_types_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert {:ok, log_types} = WebDriverClient.fetch_log_types(session)
    assert Enum.all?(log_types, &is_binary/1)
  end

  for protocol <- @protocols do
    @tag protocol: protocol
    test "fetch_log_types/1 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass} do
      scenario_server = set_up_error_scenario_tests(bypass)

      for error_scenario <- basic_error_scenarios() do
        session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)

        assert_expected_response(
          WebDriverClient.fetch_log_types(session),
          error_scenario
        )
      end
    end
  end

  @tag protocol: :jwp
  test "fetch_logs/2 with JWP session returns {:ok, log_entries} on valid response", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = JWPTestResponses.fetch_logs_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert {:ok, log_entries} = WebDriverClient.fetch_logs(session, "log_type")
    assert Enum.all?(log_entries, &match?(%LogEntry{}, &1))
  end

  @tag protocol: :w3c
  test "fetch_logs/2 with w3c session returns {:ok, [LogEntry.t()]} on valid response", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = W3CTestResponses.fetch_logs_response() |> pick()

    stub_bypass_response(bypass, resp)

    assert {:ok, log_entries} = WebDriverClient.fetch_logs(session, "log_type")
    assert Enum.all?(log_entries, &match?(%LogEntry{}, &1))
  end

  for protocol <- @protocols do
    @tag protocol: protocol
    test "fetch_logs/2 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass} do
      scenario_server = set_up_error_scenario_tests(bypass)

      for error_scenario <- basic_error_scenarios() do
        session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)

        assert_expected_response(
          WebDriverClient.fetch_logs(session, "log_type"),
          error_scenario
        )
      end
    end
  end

  @tag protocol: :jwp
  test "find_elements/3 with JWP session returns {:ok, elements} on valid response", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = JWPTestResponses.find_elements_response() |> pick()

    stub_bypass_response(bypass, resp)

    Enum.each([:css_selector, :xpath], fn strategy ->
      assert {:ok, elements} = WebDriverClient.find_elements(session, strategy, "foo")
      assert Enum.all?(elements, &match?(%Element{}, &1))
    end)
  end

  @tag protocol: :w3c
  test "find_elements/3 with W3C session returns {:ok, elements} on valid response", %{
    config: config,
    bypass: bypass
  } do
    session = TestData.session(config: constant(config)) |> pick()
    resp = W3CTestResponses.find_elements_response() |> pick()

    stub_bypass_response(bypass, resp)

    Enum.each([:css_selector, :xpath], fn strategy ->
      assert {:ok, elements} = WebDriverClient.find_elements(session, strategy, "foo")
      assert Enum.all?(elements, &match?(%Element{}, &1))
    end)
  end

  for protocol <- @protocols do
    @tag protocol: protocol
    test "find_elements/3 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass} do
      scenario_server = set_up_error_scenario_tests(bypass)

      for error_scenario <- basic_error_scenarios() do
        session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)

        assert_expected_response(
          WebDriverClient.find_elements(session, :css_selector, "foo"),
          error_scenario
        )
      end
    end
  end

  @tag protocol: :jwp
  test "find_elements_from_element/4 with JWP session returns {:ok, elements} on valid response",
       %{
         config: config,
         bypass: bypass
       } do
    session = TestData.session(config: constant(config)) |> pick()
    element = TestData.element() |> pick()
    resp = JWPTestResponses.find_elements_response() |> pick()

    stub_bypass_response(bypass, resp)

    Enum.each([:css_selector, :xpath], fn strategy ->
      assert {:ok, elements} =
               WebDriverClient.find_elements_from_element(session, element, strategy, "foo")

      assert Enum.all?(elements, &match?(%Element{}, &1))
    end)
  end

  @tag protocol: :w3c
  test "find_elements_from_element/4 with W3C session returns {:ok, elements} on valid response",
       %{
         config: config,
         bypass: bypass
       } do
    session = TestData.session(config: constant(config)) |> pick()
    element = TestData.element() |> pick()
    resp = W3CTestResponses.find_elements_response() |> pick()

    stub_bypass_response(bypass, resp)

    Enum.each([:css_selector, :xpath], fn strategy ->
      assert {:ok, elements} =
               WebDriverClient.find_elements_from_element(session, element, strategy, "foo")

      assert Enum.all?(elements, &match?(%Element{}, &1))
    end)
  end

  for protocol <- @protocols do
    @tag protocol: protocol
    test "find_elements_from_element/4 with #{protocol} session returns appropriate errors on various server responses",
         %{config: config, bypass: bypass} do
      scenario_server = set_up_error_scenario_tests(bypass)

      for error_scenario <- basic_error_scenarios() do
        session = build_session_for_scenario(scenario_server, bypass, config, error_scenario)
        element = TestData.element() |> pick()

        assert_expected_response(
          WebDriverClient.find_elements_from_element(session, element, :css_selector, "foo"),
          error_scenario
        )
      end
    end
  end

  defp build_start_session_payload do
    %{"capablities" => %{"browserName" => "firefox"}}
  end

  defp stub_bypass_response(bypass, response) do
    Bypass.stub(bypass, :any, :any, fn conn ->
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, response)
    end)
  end
end
