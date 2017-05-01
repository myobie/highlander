defmodule Highlander.Registry.Server do
  alias Highlander.Registry
  alias Highlander.Registry.ZK
  use GenServer
  require Logger

  def start_link do
    GenServer.start_link __MODULE__, [], name: __MODULE__
  end

  def init(_) do
    pids = %{}
    names = %{}

    {:ok, %{server_pids: pids, names: names}}
  end

  defp add(state, {type, id} = name, %{server_pid: server_pid} = info) when is_pid(server_pid) and is_atom(type) and is_binary(id) do
    state
    |> put_in([:server_pids, server_pid], name) # to make it easier to lookup by server_pid in case that server goes down
    |> put_in([:names, name], info)
  end

  defp delete(state, {type, id} = name) when is_atom(type) and is_binary(id) do
    case Map.get(state.names, name) do
      %{server_pid: server_pid} ->
        new_server_pids = Map.delete state.server_pids, server_pid
        new_names = Map.delete state.names, name

        %{state | server_pids: new_server_pids, names: new_names}
      nil -> state
    end
  end

  defp info(state, name) do
    Map.get(state.names, name, :undefined)
  end

  defp name(state, pid) when is_pid(pid) do
    Map.get(state.server_pids, pid)
  end

  defp server_pid(state, name) do
    case info(state, name) do
      :undefined -> :undefined
      %{server_pid: server_pid} -> server_pid
    end
  end

  defp register(state, name, pid) do
    case server_pid(state, name) do
      :undefined ->
        Logger.debug "#{node()} registering #{inspect pid} in state.pids"
        Process.monitor pid
        case ZK.create_znode(name) do
          {:ok, zk_pid} ->
            info = %{server_pid: pid, zk_pid: zk_pid}
            Logger.debug "#{node()} adding #{inspect name}/(#{inspect info}) to state.pids"
            {:ok, add(state, name, info)}
          {:error, reason} ->
            Logger.debug "#{node()} there was an error creating the zookeeper node for #{inspect name}: #{inspect reason} (not updating state.pids)"
            {:error, reason, state}
        end
      _ ->
        Logger.debug "#{node()} register_name: already registered #{inspect name} in state.pids"
        {:error, :already_registered, state}
    end
  end

  defp unregister(state, { _type, _id } = name) do
    Logger.debug "#{node()} remove(#{inspect name})"
    case info(state, name) do
      :undefined ->
        Logger.debug "#{node()} not in my state.pids"
        state
      %{server_pid: server_pid, zk_pid: zk_pid} ->
        Logger.debug "#{node()} in my state.pids: #{inspect server_pid}"
        :ok = ZK.delete_znode(zk_pid)
        delete(state, name)
    end
  end

  defp unregister(state, pid) when is_pid(pid) do
    unregister(state, name(state, pid))
  end

  defp unregister(state, nil), do: state

  defp resolve(node_name) when is_binary(node_name) do
    if node_name == to_string(Node.self) do
      Node.self
    else
      Node.list(:known)
      |> Enum.find(:unreachable, &(node_name == to_string(&1)))
    end
  end
  defp resolve(nil), do: nil

  defp whereis_on_node(node_name, name) do
    case resolve(node_name) do
      :unreachable ->
        Logger.debug "#{node()} -> #{node_name} is unreachable"
        :undefined
      node ->
        Logger.debug "#{node} found #{node_name}: #{inspect([name, node])}"
        case :rpc.call(node, Registry, :whereis_name, [name, local: true]) do
          {:badrpc, _reason} -> :undefined
          result -> result
        end
    end
  end

  defp whereis_remote(name) do
    case ZK.get_node_name(name) do
      :undefined ->
        Logger.debug "#{node()} didn't find #{inspect name} in zookeeper"
        :undefined
      node_name ->
        Logger.debug "#{node()} found #{inspect name} in zookeeper: #{inspect node_name}"
        whereis_on_node(node_name, name)
    end
  end

  def handle_call({:whereis_name, name, opts}, _from, state) do
    Logger.debug "#{node()} handle_call whereis_name: #{inspect name}"
    case info(state, name) do
      :undefined ->
        if Keyword.get(opts, :local) do
          {:reply, :undefined, state}
        else
          Logger.debug "#{node()} not in my state.pids"
          {:reply, whereis_remote(name), state}
        end
      %{server_pid: server_pid} ->
        Logger.debug "#{node()} in my state.pids: #{inspect server_pid}"
        {:reply, server_pid, state}
    end
  end

  def handle_call({:register_name, name, pid}, _from, state) do
    case register(state, name, pid) do
      {:ok, state} -> {:reply, :yes, state}
      {:error, _reason, state} -> {:reply, :no, state}
    end
  end

  def handle_cast({:unregister_name, name}, state) do
    Logger.debug "#{node()} unregister_name: #{inspect name}"
    {:noreply, unregister(state, name)}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    Logger.debug "#{node()} :DOWN: #{inspect pid}"
    {:noreply, unregister(state, pid)}
  end

  def terminate(reason, _state) do
    Logger.error "Registry.Server terminate #{inspect(reason)}"
  end
end
