defmodule Highlander.PersistedState do
  require Logger

  def get({type, id}) do
    bucket = "objects:#{type}:#{id}"
    case Redix.command!(:redix, ~w(GET #{bucket})) do
      nil -> %{}
      "" -> %{}
      value ->
        Logger.debug "value in redis for #{bucket}: #{inspect value}"
        Poison.decode!(value)
    end
  end

  def put({type, id}, state) do
    json = Poison.encode!(state)
    bucket = "objects:#{type}:#{id}"
    Logger.debug "setting into redis for #{bucket}: #{inspect json}"
    Redix.command!(:redix, ~w(SET #{bucket} #{json}))
  end
end
