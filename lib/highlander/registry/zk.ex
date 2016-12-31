defmodule Highlander.Registry.ZK do
  import Highlander.Registry.ZK.Helpers
  alias Highlander.Registry.ZK.Node

  def create_node({ type, _id } = name) when is_atom(type) do
    Node.start_link(name)
  end

  def get_children({ type, _id } = name) when is_atom(type) do
    case Zookeeper.Client.get_children(:zk, path(name)) do
      {:ok, children } -> children
      {:error, :no_node} -> []
    end
  end

  def get_first({ type, _id } = name) when is_atom(type) do
    get_children(name)
    |> sort
    |> first
  end

  def get_hostname({ type, _id } = name) when is_atom(type) do
    get_hostname(name, get_first(name))
  end

  def get_hostname(_name, nil), do: :undefined

  def get_hostname({ type, _id } = name, node_name) when is_atom(type) and is_binary(node_name) do
    case Zookeeper.Client.get(:zk, path(name, node_name)) do
      {:ok, value} -> value
      _ -> :undefined
    end
  end

  def first?({ type, _id } = name, << _ :: size(256), "-", _ :: binary >> = node_name) when is_atom(type) do
    get_first(path(name)) == node_name
  end
end
