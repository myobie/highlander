defmodule Highlander.FileStore do
  @type key :: String.t
  @type data :: binary
  @type options :: keyword

  @callback put(key, data, options) :: :ok | {:error, atom}
  @callback get(key) :: {:ok, data} | {:error, atom}

  @spec config() :: keyword
  def config do
    Application.get_env(:highlander, __MODULE__, [])
  end

  @spec adapter() :: __MODULE__
  def adapter do
    config() |> Keyword.get(:adapter, Highlander.MissingFileStore)
  end
end

defmodule Highlander.MissingFileStore do
  @behaviour Highlander.FileStore

  def put(_key, _data, _options), do: {:error, :no_file_store_adapter_specified_in_config}
  def get(_key), do: {:error, :no_file_store_adapter_specified_in_config}
end
