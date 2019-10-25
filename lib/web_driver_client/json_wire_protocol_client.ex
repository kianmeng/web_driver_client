defmodule WebDriverClient.JSONWireProtocolClient do
  @moduledoc false

  import WebDriverClient.Guards

  alias Tesla.Env
  alias WebDriverClient.Config
  alias WebDriverClient.HTTPClientError
  alias WebDriverClient.Session
  alias WebDriverClient.Size
  alias WebDriverClient.TeslaClientBuilder
  alias WebDriverClient.UnexpectedResponseFormatError
  alias WebDriverClient.UnexpectedStatusCodeError

  @spec fetch_window_size(Session.t()) ::
          {:ok, Size.t()} | {:error, HTTPClientError.t() | UnexpectedStatusCodeError.t()}
  def fetch_window_size(%Session{id: id, config: %Config{} = config})
      when is_session_id(id) do
    client = TeslaClientBuilder.build(config)
    window_handle = "current"

    url = "/session/#{id}/window/#{window_handle}/size"

    with {:ok, %Env{body: body}} <- Tesla.get(client, url),
         {:ok, size} <- parse_size(body) do
      {:ok, size}
    end
  end

  @type size_opt :: {:width, pos_integer} | {:height, pos_integer}

  @spec set_window_size(Session.t(), [size_opt]) ::
          :ok | {:error, HTTPClientError.t() | UnexpectedStatusCodeError.t()}
  def set_window_size(%Session{id: id, config: %Config{} = config}, opts \\ [])
      when is_list(opts) do
    window_handle = "current"
    url = "/session/#{id}/window/#{window_handle}/size"

    request_body = opts |> Keyword.take([:height, :width]) |> Map.new()

    config
    |> TeslaClientBuilder.build()
    |> Tesla.post(url, request_body)
    |> case do
      {:ok, %Env{}} ->
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec parse_size(term) :: {:ok, Size.t()} | {:error, UnexpectedResponseFormatError.t()}
  defp parse_size(%{"value" => %{"width" => width, "height" => height}}) do
    {:ok, %Size{width: width, height: height}}
  end

  defp parse_size(body) do
    {:error, UnexpectedResponseFormatError.exception(response_body: body)}
  end
end