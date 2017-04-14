defmodule Highlander.Registry.NodeCycleServer do
  use GenServer

  def start_link do
    GenServer.start_link __MODULE__, [], name: __MODULE__
  end

  def init(_) do
    {:ok, %{nodes: Node.list(:known), index: 0}}
  end

  def handle_call(:next, _from, %{nodes: nodes, index: index} = state) do
    index = index + 1

    {node_name, nodes, index} = case Enum.fetch(nodes, index) do
      {:ok, value} -> {value, nodes, index}
      :error ->
        index = 0
        nodes = Node.list(:known)
        {List.first(nodes), nodes, index}
    end

    new_state = %{state | nodes: nodes, index: index}
    {:reply, node_name, new_state}
  end
end
