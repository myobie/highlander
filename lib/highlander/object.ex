defmodule Highlander.Object do
  alias Highlander.Registry
  alias Highlander.Object.{Server, Supervisor}

  defdelegate next_node, to: Registry
  defdelegate via_tuple(user_id), to: Server
  defdelegate start_child(supervisor, child_spec_or_args), to: Elixir.Supervisor

  @type address :: {atom, binary}

  @callback get(binary) :: {:ok, map} | no_return
  @callback put(binary, map) :: :ok | no_return

  defmacro __using__([type: type]) do
    quote do
      @behaviour unquote(__MODULE__)
      import unquote(__MODULE__), only: [defobject: 1]

      def get(id) do
        unquote(__MODULE__).get_persisted_state({unquote(type), id})
      end

      def put(id, new_persisted_state) do
        unquote(__MODULE__).put_persisted_state({unquote(type), id}, new_persisted_state)
      end

      defoverridable get: 1, put: 2
    end
  end

  defmacro defobject(opts) do
    quote do
      defstruct unquote(opts)

      def get(id) do
        {:ok, state} = super(id)

        object = Keyword.keys(unquote(opts))
                 |> Enum.reduce(%__MODULE__{}, fn (key, object) ->
                   case Map.get(state, to_string(key)) do
                     nil -> object
                     value -> Map.put object, key, value
                   end
                 end)

        {:ok, object}
      end

      def put(id, new_object) do
        state = Keyword.keys(unquote(opts))
                |> Enum.reduce(%{}, fn (key, state) ->
                  Map.put state, to_string(key), Map.get(new_object, key)
                end)

        {:ok, _} = super(id, state)

        {:ok, new_object}
      end
    end
  end

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

  def get_persisted_state({type, id}) do
    startup_and_call {type, id}, {:get_persisted_state}
  end

  def put_persisted_state({type, id}, new_persisted_state) do
    startup_and_call {type, id}, {:put_persisted_state, new_persisted_state}
  end
end
