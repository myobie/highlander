defmodule Highlander.Registry.Server do
  use GenServer
  require Logger

  def start_link do
    GenServer.start_link __MODULE__, [], name: __MODULE__
  end

  def init(_) do
    pids = %{}
    names = %{}

    hostname = Map.get_lazy System.get_env, "ACTOR_HOSTNAME", fn -> UUID.uuid1(:hex) end

    {:ok, %{pids: pids, names: names, hostname: hostname}}
  end

  def add(state, {type, id} = name, pid) when is_pid(pid) and is_atom(type) and is_binary(id) do
    state
    |> put_in([:pids, name], pid)
    |> put_in([:names, pid], name)
  end

  def delete(%{pids: pids, names: names} = state, {type, id} = name) when is_atom(type) and is_binary(id) do
    pid = Map.get pids, name
    new_pids = Map.delete pids, name
    new_names = Map.delete names, pid

    %{state | pids: new_pids, names: new_names}
  end

  def delete(%{names: names} = state, pid) when is_pid(pid) do
    name = Map.get names, pid
    delete state, name
  end

  def delete(state, nil) do
    Logger.error "Attempting to delete nil from the registry state"
    state
  end

  def handle_call({:hostname}, _from, %{hostname: hostname} = state) do
    {:reply, hostname, state}
  end

  def handle_call({:whereis_name, name}, _from, state) do
    pid = Map.get state.pids, name, :undefined
    {:reply, pid, state}
  end

  def handle_call({:register_name, name, pid}, _from, %{pids: pids} = state) do
    case Map.get(pids, name) do
      nil ->
        Process.monitor pid
        new_state = add state, name, pid
        {:reply, :yes, new_state}
      _ ->
        {:reply, :no, state}
    end
  end

  def handle_cast({:unregister_name, name}, state) do
    new_state = delete state, name
    {:noreply, new_state}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    new_state = delete state, pid
    {:noreply, new_state}
  end

  def terminate(reason, _state) do
    Logger.error "Registry.Server terminate #{inspect(reason)}"
  end
end
