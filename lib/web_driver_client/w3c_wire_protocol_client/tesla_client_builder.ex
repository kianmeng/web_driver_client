defmodule WebDriverClient.W3CWireProtocolClient.TeslaClientBuilder do
  @moduledoc false
  alias Tesla.Client
  alias WebDriverClient.Config

  @spec build(Config.t()) :: Client.t()
  def build(%Config{base_url: base_url, debug?: debug?}) do
    adapter = {Tesla.Adapter.Hackney, [recv_timeout: 30_000]}

    middleware =
      [
        {Tesla.Middleware.BaseUrl, base_url},
        WebDriverClient.W3CWireProtocolClient.Middleware.ErrorResponseHandler,
        WebDriverClient.W3CWireProtocolClient.Middleware.ParseJSON,
        Tesla.Middleware.EncodeJson,
        WebDriverClient.Middleware.HTTPClientErrorHandler,
        Tesla.Middleware.Logger
      ]
      |> Enum.reject(fn
        Tesla.Middleware.Logger -> !debug?
        _ -> false
      end)

    Tesla.client(middleware, adapter)
  end

  @spec build_simple(Config.t()) :: Client.t()
  def build_simple(%Config{base_url: base_url, debug?: debug?}) do
    adapter = {Tesla.Adapter.Hackney, [recv_timeout: 30_000]}

    middleware =
      [
        {Tesla.Middleware.BaseUrl, base_url},
        Tesla.Middleware.EncodeJson,
        WebDriverClient.Middleware.HTTPClientErrorHandler,
        Tesla.Middleware.Logger
      ]
      |> Enum.reject(fn
        Tesla.Middleware.Logger -> !debug?
        _ -> false
      end)

    Tesla.client(middleware, adapter)
  end
end
