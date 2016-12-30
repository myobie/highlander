defmodule Highlander.Registry do
  require Logger
  @server Highlander.Registry.Server

  def hostname do
    GenServer.call(@server, {:hostname})
  end

  # A safe way to call other processes that will not crash if the other process is not found
  def call(via, message) do
    try do
      {:ok, GenServer.call(via, message)}
    catch
      # I am not sure what to catch here, so I'm trying to be very specific
      :exit, {:noproc, _} -> {:error, :process_not_found}
    end
  end

  def lookup(via) do
    GenServer.whereis(via)
  end

  def shutdown(_via) do
  end

  # via callbacks

  def send(name, message) do
    case whereis_name(name) do
      :undefined -> {:badarg, {name, message}}
      pid ->
        Kernel.send pid, message
        pid
    end
  end

  def whereis_name(name) do
    GenServer.call(@server, {:whereis_name, name})
  end

  def register_name(name, pid) do
    GenServer.call(@server, {:register_name, name, pid})
  end

  def unregister_name(name) do
    GenServer.cast(@server, {:unregister_name, name})
  end
end
