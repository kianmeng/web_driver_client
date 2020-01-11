defmodule WebDriverClient.W3CWireProtocolClient.Commands.FindElements do
  @moduledoc false

  import WebDriverClient.W3CWireProtocolClient.Guards

  alias WebDriverClient.Config
  alias WebDriverClient.Element
  alias WebDriverClient.HTTPClientError
  alias WebDriverClient.HTTPResponse
  alias WebDriverClient.Session
  alias WebDriverClient.W3CWireProtocolClient
  alias WebDriverClient.W3CWireProtocolClient.ResponseParser
  alias WebDriverClient.W3CWireProtocolClient.TeslaClientBuilder
  alias WebDriverClient.W3CWireProtocolClient.UnexpectedResponseError
  alias WebDriverClient.W3CWireProtocolClient.WebDriverError

  @type element_location_strategy :: W3CWireProtocolClient.element_location_strategy()
  @type element_selector :: W3CWireProtocolClient.element_selector()

  @spec send_request(Session.t(), element_location_strategy, element_selector) ::
          {:ok, HTTPResponse.t()} | {:error, HTTPClientError.t()}

  def send_request(
        %Session{id: id, config: %Config{} = config},
        element_location_strategy,
        element_selector
      )
      when is_element_location_strategy(element_location_strategy) and
             is_element_selector(element_selector) do
    client = TeslaClientBuilder.build_simple(config)
    url = "/session/#{id}/elements"

    request_body = %{
      "using" => element_location_strategy_to_string(element_location_strategy),
      "value" => element_selector
    }

    case Tesla.post(client, url, request_body) do
      {:ok, env} ->
        {:ok, HTTPResponse.build(env)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec parse_response(HTTPResponse.t()) ::
          {:ok, [Element.t()]} | {:error, UnexpectedResponseError.t() | WebDriverError.t()}
  def parse_response(%HTTPResponse{} = http_response) do
    with {:ok, w3c_response} <- ResponseParser.parse_response(http_response),
         :ok <- ResponseParser.ensure_successful_response(w3c_response),
         {:ok, elements} <- ResponseParser.parse_elements(w3c_response) do
      {:ok, elements}
    end
  end

  @spec element_location_strategy_to_string(element_location_strategy) :: String.t()
  defp element_location_strategy_to_string(:css_selector), do: "css selector"
  defp element_location_strategy_to_string(:xpath), do: "xpath"
end
