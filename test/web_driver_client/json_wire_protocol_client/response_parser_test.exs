defmodule WebDriverClient.JSONWireProtocolClient.ResponseParserTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias WebDriverClient.Element
  alias WebDriverClient.JSONWireProtocolClient.LogEntry
  alias WebDriverClient.JSONWireProtocolClient.ResponseParser
  alias WebDriverClient.JSONWireProtocolClient.TestResponses
  alias WebDriverClient.Session
  alias WebDriverClient.Size
  alias WebDriverClient.TestData
  alias WebDriverClient.UnexpectedResponseFormatError

  property "parse_value/1 returns {:ok, url} when result is a string" do
    check all value <-
                one_of([
                  integer(),
                  list_of(url(), max_length: 3),
                  map_of(
                    string(:alphanumeric, max_length: 10),
                    string(:alphanumeric, max_length: 10),
                    max_length: 3
                  )
                ]) do
      response = %{"value" => value}

      assert {:ok, ^value} = ResponseParser.parse_value(response)
    end
  end

  test "parse_value/1 returns {:error, %UnexpectedResponseFormatError{}} on an invalid response" do
    for response <- [[], %{}] do
      assert {:error, %UnexpectedResponseFormatError{response_body: ^response}} =
               ResponseParser.parse_value(response)
    end
  end

  property "parse_url/1 returns {:ok, url} when result is a string" do
    check all url <- url() do
      response = %{"value" => url}

      assert {:ok, ^url} = ResponseParser.parse_url(response)
    end
  end

  property "parse_url/1 returns {:error, %UnexpectedResponseFormatError{}} on an invalid response" do
    check all response <-
                one_of([
                  constant(%{}),
                  fixed_map(%{
                    "value" =>
                      one_of([
                        integer(),
                        list_of(url(), max_length: 3),
                        map_of(
                          string(:alphanumeric, max_length: 10),
                          string(:alphanumeric, max_length: 10),
                          max_length: 3
                        )
                      ])
                  })
                ]) do
      assert {:error, %UnexpectedResponseFormatError{response_body: ^response}} =
               ResponseParser.parse_url(response)
    end
  end

  property "parse_size/1 returns {:ok, %Size{}} on valid response" do
    check all width <- integer(0..1000),
              height <- integer(0..1000) do
      response = %{"value" => %{"width" => width, "height" => height}}

      assert {:ok, %Size{width: ^width, height: ^height}} = ResponseParser.parse_size(response)
    end
  end

  property "parse_size/1 returns {:error, %UnexpectedResponseFormatError{}} on an invalid response" do
    check all response <-
                one_of([
                  constant(%{}),
                  fixed_map(%{
                    "value" =>
                      fixed_map(%{
                        "width" => string(:alphanumeric),
                        "height" => string(:alphanumeric)
                      })
                  })
                ]) do
      assert {:error, %UnexpectedResponseFormatError{response_body: ^response}} =
               ResponseParser.parse_size(response)
    end
  end

  property "parse_log_entries/1 returns {:ok [%LogEntry{}]} when all log entries are valid" do
    check all unparsed_log_entries <- list_of(TestResponses.log_entry(), max_length: 10) do
      response = %{"value" => unparsed_log_entries}

      expected_log_entries =
        Enum.map(unparsed_log_entries, fn %{
                                            "level" => level,
                                            "message" => message,
                                            "timestamp" => timestamp
                                          } = raw_entry ->
          %LogEntry{
            level: level,
            message: message,
            timestamp: DateTime.from_unix!(timestamp, :millisecond),
            source: Map.get(raw_entry, "source")
          }
        end)

      assert {:ok, ^expected_log_entries} = ResponseParser.parse_log_entries(response)
    end
  end

  property "parse_log_entries/1 returns {:error, %UnexpectedResponseFormatError{}} on an invalid response" do
    check all response <-
                one_of([
                  constant(%{}),
                  fixed_map(%{
                    "value" => log_entries_with_invalid_responses()
                  })
                ]) do
      assert {:error, %UnexpectedResponseFormatError{response_body: ^response}} =
               ResponseParser.parse_log_entries(response)
    end
  end

  property "parse_elements/1 returns {:ok [%Element{}]} when all log entries are valid" do
    check all unparsed_elements <- list_of(TestResponses.element(), max_length: 10) do
      response = %{"value" => unparsed_elements}

      expected_elements =
        Enum.map(unparsed_elements, fn %{
                                         "ELEMENT" => element_id
                                       } ->
          %Element{
            id: element_id
          }
        end)

      assert {:ok, ^expected_elements} = ResponseParser.parse_elements(response)
    end
  end

  property "parse_elements/1 returns {:error, %UnexpectedResponseFormatError{}} on an invalid response" do
    check all response <-
                one_of([
                  constant(%{}),
                  fixed_map(%{
                    "value" => elements_with_invalid_responses()
                  })
                ]) do
      assert {:error, %UnexpectedResponseFormatError{response_body: ^response}} =
               ResponseParser.parse_elements(response)
    end
  end

  test "parse_fetch_sessions_response/2 returns {:ok [%Session{}]} when all sessions are valid" do
    config = TestData.config() |> pick()
    resp = TestResponses.fetch_sessions_response() |> pick() |> Jason.decode!()

    session_id =
      resp
      |> Map.fetch!("value")
      |> List.first()
      |> Map.fetch!("id")

    assert {:ok, [%Session{id: ^session_id, config: ^config}]} =
             ResponseParser.parse_fetch_sessions_response(resp, config)
  end

  test "parse_fetch_sessions_response/2 returns {:error, %UnexpectedResponseFormatError{}} on an invalid response" do
    config = TestData.config() |> pick()
    response = %{}

    assert {:error, %UnexpectedResponseFormatError{response_body: ^response}} =
             ResponseParser.parse_fetch_sessions_response(response, config)
  end

  defp elements_with_invalid_responses do
    gen all valid_elements <- list_of(TestResponses.element(), max_length: 10),
            invalid_elements <- list_of(constant(%{}), min_length: 1, max_length: 10) do
      [valid_elements, invalid_elements]
      |> List.flatten()
      |> Enum.shuffle()
    end
  end

  defp log_entries_with_invalid_responses do
    gen all valid_log_entries <- list_of(TestResponses.log_entry(), max_length: 10),
            invalid_log_entries <- list_of(constant(%{}), min_length: 1, max_length: 10) do
      [valid_log_entries, invalid_log_entries]
      |> List.flatten()
      |> Enum.shuffle()
    end
  end

  defp url do
    string(:alphanumeric)
  end
end
