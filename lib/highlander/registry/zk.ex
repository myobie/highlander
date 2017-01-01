defmodule Highlander.Registry.ZK do
  require Logger
  import Highlander.Registry.ZK.Helpers
  alias Highlander.Registry.ZK.ZNode

  def create_znode({ type, _id } = name) when is_atom(type) do
    {:ok, pid} = ZNode.start_link(name)

    if ZNode.first?(pid) do
      {:ok, pid}
    else
      :ok = ZNode.delete(pid)
      {:error, :already_exists}
    end
  end

  def delete_znode(pid) when is_pid(pid) do
    :ok = ZNode.delete(pid)
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

  def get_node_name({ type, _id } = name) when is_atom(type) do
    get_node_name(name, get_first(name))
  end

  def get_node_name(_name, nil), do: :undefined

  def get_node_name({ type, _id } = name, znode_name) when is_atom(type) and is_binary(znode_name) do
    case Zookeeper.Client.get(:zk, path(name, znode_name)) do
      {:ok, {value, _stat}} ->
        Logger.debug "#{node} value in zookeeper for #{path(name, znode_name)}: #{inspect value}"
        value
      _ -> :undefined
    end
  end

  def first?({ type, _id } = name, << _ :: size(256), "-", _ :: binary >> = znode_name) when is_atom(type) do
    get_first(name) == znode_name
  end
end
