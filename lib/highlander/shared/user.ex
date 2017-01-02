defmodule Highlander.Shared.User do
  alias Highlander.Registry
  alias Highlander.Shared.User.{Server, Supervisor}

  defdelegate via_tuple(user_id), to: Server
  defdelegate start_child(supervisor, child_spec_or_args), to: Elixir.Supervisor

  def startup(user_id, opts \\ []) do
    cond do
      opts[:local] ->
        start_child(Supervisor, [%{user_id: user_id}])
      opts[:node] ->
        case :rpc.call(opts[:node], __MODULE__, :startup, [user_id, [local: true]]) do
          {:badrpc, _reason} -> {:error, :unreachable}
          result -> result
        end
      true ->
        startup(user_id, node: Registry.next_node)
    end
  end

  def lookup(user_id) do
    Registry.lookup via_tuple(user_id)
  end

  def shutdown(user_id) do
    Registry.shutdown via_tuple(user_id)
  end

  def call(user_id, message) do
    Registry.call via_tuple(user_id), message
  end

  def startup_and_call(user_id, message) do
    case call(user_id, message) do
      {:error, :process_not_found} ->
        {:ok, _pid} = startup(user_id)
        call(user_id, message)
      result -> result
    end
  end

  def get_in_memory_state(user_id) do
    call user_id, {:get_state}
  end

  def get_info(user_id) do
    startup_and_call user_id, {:get_info}
  end

  def set_info(user_id, new_info) do
    startup_and_call user_id, {:set_info, new_info}
  end

  def update_info(user_id, new_info) do
    startup_and_call user_id, {:update_info, new_info}
  end
end

defmodule Highlander.Shared.User.Supervisor do
  use Supervisor
  alias Highlander.Shared.User.Server

  def start_link do
    Supervisor.start_link __MODULE__, [], name: __MODULE__
  end

  def init(_) do
    children = [
      worker(Server, [], [restart: :transient])
    ]

    supervise children, strategy: :simple_one_for_one
  end
end

defmodule Highlander.Shared.User.Server do
  alias Highlander.Shared.Info
  require Logger
  use GenServer

  def start_link(%{user_id: user_id} = opts) do
    GenServer.start_link(__MODULE__, opts, name: via_tuple(user_id))
  end

  def via_tuple(user_id) do
    {:via, Highlander.Registry, {:user, user_id}}
  end

  def bucket(user_id) do
    "bucket:user:#{user_id}"
  end

  def init(%{ user_id: user_id }) do
    info = Info.get(bucket(user_id))
    {:ok, %{id: user_id, info: info}}
  end

  def handle_call({:get_state}, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:get_info}, _from, %{info: info} = state) do
    {:reply, info, state}
  end

  def handle_call({:set_info, info}, _from, state) do
    Info.set(bucket(state.id), info)
    new_state = %{state | info: info}
    {:reply, info, new_state}
  end

  def terminate(reason, _state) do
    Logger.error "User.Server terminate #{inspect(reason)}"
  end
end
