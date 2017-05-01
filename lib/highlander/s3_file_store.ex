defmodule Highlander.S3FileStore do
  alias Highlander.FileStore

  @behaviour FileStore
  @default_bucket "elixir-s3-file-store-default"

  def put(key, data, [content_type: content_type, acl: acl]) do
    case perform_upload_request(key, data, content_type: content_type, acl: acl) do
      {:ok, _response} -> :ok
      error -> error
    end
  end

  def put(key, data, [content_type: content_type]) do
    put(key, data, content_type: content_type, acl: :private)
  end

  def put(_key, _data, _options) do
    {:error, :incorrect_s3_upload_options}
  end

  def get(key) do
    case perform_download_request(key) do
      {:ok, %{body: body}} -> {:ok, body}
      {:ok, _} -> {:error, :internal_server_error}
      error -> error
    end
  end

  @spec bucket() :: String.t
  defp bucket do
    FileStore.config() |> Keyword.get(:bucket, @default_bucket)
  end

  @spec perform_upload_request(String.t, binary, keyword) :: {:ok, term} | {:error, term}
  defp perform_upload_request(key, data, options) do
    bucket()
    |> ExAws.S3.put_object(key, data, options)
    |> ExAws.request
  end

  @spec perform_download_request(String.t) :: {:ok, term} | {:error, term}
  defp perform_download_request(key) do
    bucket()
    |> ExAws.S3.get_object(key)
    |> ExAws.request
  end
end
