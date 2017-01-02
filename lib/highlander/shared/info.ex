defmodule Highlander.Shared.Info do
  require Logger
  alias Highlander.Shared.Info.Server

  def get(bucket) do
    case Redix.command!(:redix, ~w(GET #{bucket})) do
      nil -> %{}
      "" -> %{}
      value ->
        Logger.debug "value in redis for #{bucket}: #{inspect value}"
        Poison.decode!(value)
    end
  end

  def set(bucket, info) do
    json = Poison.encode!(info)
    Logger.debug "setting into redis for #{bucket}: #{inspect json}"
    Redix.command!(:redix, ~w(SET #{bucket} #{json}))
  end
end
