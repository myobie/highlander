defmodule Highlander.Registry.ZK.ZNode do
  require Logger
  use GenServer
  import Highlander.Registry.ZK.Helpers
  alias Highlander.Registry.ZK

  def start_link(name) do
    GenServer.start_link __MODULE__, name
  end

  def delete(pid) do
    GenServer.stop(pid)
  end

  def first?(pid) do
    GenServer.call(pid, :first?)
  end

  def name(pid) do
    GenServer.call(pid, :znode_name)
  end

  # Server

  def init({type, _id} = name) when is_atom(type) do
    uuid = UUID.uuid4(:hex)
    path_prefix = prefix(name, uuid)
    node_name = to_string Node.self

    Logger.debug "#{node()} creating #{path_prefix}: [#{node_name}] in zookeeper"
    {:ok, created_path} = Zookeeper.Client.create(:zk, path_prefix, node_name, makepath: true, create_mode: :ephemeral_sequential)

    znode_name = Path.basename(created_path)
    state = %{znode_name: znode_name, name: name}

    {:ok, state}
  end

  def terminate(_reason, %{name: name, znode_name: znode_name}) do
    Logger.debug "#{node()} deleteing #{path(name, znode_name)}"
    Zookeeper.Client.delete(:zk, path(name, znode_name))
  end

  def handle_call(:first?, _from, %{name: name, znode_name: znode_name} = state) do
    {:reply, ZK.first?(name, znode_name), state}
  end

  def handle_call(:znode_name, _from, %{znode_name: znode_name} = state) do
    {:reply, znode_name, state}
  end
end
