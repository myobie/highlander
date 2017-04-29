defmodule Highlander.Object.Server do
  alias Highlander.{Registry, PersistedState}
  require Logger
  use GenServer

  def start_link(%{id: id, type: type} = opts) do
    GenServer.start_link(__MODULE__, opts, name: via_tuple({type, id}))
  end

  def via_tuple({type, id}) do
    {:via, Registry, {type, id}}
  end

  def init(%{ id: id, type: type }) do
    persisted_state = PersistedState.get({type, id})
    {:ok, %{id: id, type: type, persisted_state: persisted_state}}
  end

  def handle_call({:get_state}, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:get_persisted_state}, _from, %{persisted_state: persisted_state} = state) do
    {:reply, persisted_state, state}
  end

  def handle_call({:put_persisted_state, persisted_state}, _from, state) do
    PersistedState.put({state.type, state.id}, persisted_state)
    new_state = %{state | persisted_state: persisted_state}
    {:reply, :ok, new_state}
  end

  def terminate(reason, state) do
    Logger.error "Object.Server #{{state.type, state.id}} terminate #{inspect(reason)}"
    :ok
  end
end
