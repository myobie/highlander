defmodule Highlander.Registry.ZK.Node do
  use GenServer
  import Highlander.Registry.ZK.Helpers
  alias Highlander.Registry.ZK

  def start_link(name) do
    GenServer.start_link __MODULE__, name
  end

  def first?(pid) do
    GenServer.call(pid, :first?)
  end

  # Server

  def init({type, _id} = name) when is_atom(type) do
    uuid = UUID.uuid4(:hex)
    path_prefix = prefix(name, uuid)
    hostname = to_string Node.self

    {:ok, created_path} = Zookeeper.Client.create(:zk, path_prefix, hostname, makepath: true, create_mode: :ephemeral_sequential)

    node_name = Path.basename(created_path)
    state = %{node_name: node_name, name: name}

    {:ok, state}
  end

  def terminate(_reason, %{name: name, node_name: node_name}) do
    Zookeeper.Client.delete(:zk, path(name, node_name))
  end

  def handle_call(:first?, _from, %{name: name, node_name: node_name}) do
    ZK.first?(name, node_name)
  end
end
