defmodule Highlander.Object do
  alias Highlander.Registry
  alias Highlander.Object.{Server, Supervisor}

  defdelegate next_node, to: Registry
  defdelegate via_tuple(user_id), to: Server
  defdelegate start_child(supervisor, child_spec_or_args), to: Elixir.Supervisor

  def startup({type, id}, opts \\ []) do
    cond do
      opts[:local] ->
        start_child Supervisor, [%{id: id, type: type}]
      opts[:node] ->
        case :rpc.call(opts[:node], __MODULE__, :startup, [{type, id}, [local: true]]) do
          {:badrpc, _reason} -> {:error, :unreachable}
          result -> result
        end
      true ->
        startup {type, id}, node: next_node()
    end
  end

  def lookup({type, id}) do
    Registry.lookup via_tuple({type, id})
  end

  def shutdown({type, id}) do
    Registry.shutdown via_tuple({type, id})
  end

  def call({type, id}, message) do
    Registry.call via_tuple({type, id}), message
  end

  def startup_and_call({type, id}, message) do
    case call({type, id}, message) do
      {:error, :process_not_found} ->
        {:ok, _pid} = startup {type, id}
        call {type, id}, message
      result -> result
    end
  end

  def get_in_memory_state({type, id}) do
    call {type, id}, {:get_state}
  end

  def get({type, id}) do
    startup_and_call {type, id}, {:get_persisted_state}
  end

  def put({type, id}, new_persisted_state) do
    startup_and_call {type, id}, {:put_persisted_state, new_persisted_state}
  end
end
