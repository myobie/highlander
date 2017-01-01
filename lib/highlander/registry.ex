defmodule Highlander.Registry do
  require Logger
  alias Highlander.Registry.Server

  @timeout 500

  def hostname do
    GenServer.call(Server, {:hostname})
  end

  # A safe way to run a function on another node (must share the same code)
  def call(node, func) when is_atom(node) do
    parent = self
    ref = make_ref

    pid = Node.spawn_link(node, fn ->
      result = func.()
      Kernel.send parent, {ref, result}
      ref = Process.monitor(parent)
      receive do
        {:DOWN, ^ref, :process, _, _} -> :ok
      end
    end)

    receive do
      {^ref, result} -> result
    after
      @timeout -> {pid, {:error, :timeout}}
    end
  end

  # A safe way to call other processes that will not crash if the other process is not found
  def call({:via, _, _} = via, message) do
    try do
      {:ok, GenServer.call(via, message)}
    catch
      # I am not sure what to catch here, so I'm trying to be very specific
      :exit, {:noproc, _} -> {:error, :process_not_found}
    end
  end

  def lookup({:via, _, _} = via) do
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

  def whereis_name(name, opts \\ []) do
    Logger.debug "#{node} whereis_name: #{inspect name}"
    GenServer.call(Server, {:whereis_name, name, opts})
  end

  def register_name(name, pid) do
    Logger.debug "#{node} register_name: #{inspect name}"
    GenServer.call(Server, {:register_name, name, pid})
  end

  def unregister_name(name) do
    Logger.debug "#{node} unregister_name: #{inspect name}"
    GenServer.cast(Server, {:unregister_name, name})
  end
end
