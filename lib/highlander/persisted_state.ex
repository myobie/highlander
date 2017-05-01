defmodule Highlander.PersistedState do
  alias Highlander.FileStore
  require Logger

  def get({type, id}) do
    key = "objects/#{type}/#{id}.json"
    case FileStore.adapter().get(key) do
      {:error, :file_not_found} -> %{}
      {:ok, data} ->
        Logger.debug "value in redis for #{key}: #{inspect data}"
        Poison.decode!(data)
      {:error, _} -> throw "error getting #{key}"
    end
  end

  def put({type, id}, state) do
    json = Poison.encode!(state)
    key = "objects/#{type}/#{id}.json"
    Logger.debug "saving file for #{key}: #{inspect json}"

    case FileStore.adapter().put(key, json, content_type: "application/json") do
      :ok -> :ok
      {:error, _} -> throw "error saving #{key}"
    end
  end
end
