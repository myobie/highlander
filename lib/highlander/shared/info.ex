defmodule Highlander.Shared.Info do
  alias Highlander.Shared.Info.Server

  def get(bucket) do
    GenServer.call Server, {:get, bucket}
  end

  def set(bucket, info) do
    GenServer.call Server, {:set, bucket, info}
  end
end

defmodule Highlander.Shared.Info.Server do
  use GenServer

  # TODO: use redis or sqlite or something

  @empty_info %{}

  def start_link do
    GenServer.start_link __MODULE__, [], name: __MODULE__
  end

  def init(_) do
    {:ok, %{}}
  end

  def handle_call({:set, bucket, info}, _from, state) do
    new_state = Map.put state, bucket, info
    {:reply, info, new_state}
  end

  def handle_call({:get, bucket}, _from, state) do
    info = Map.get(state, bucket, @empty_info)
    {:reply, info, state}
  end
end
