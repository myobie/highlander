defmodule Highlander.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link __MODULE__, [], name: __MODULE__
  end

  def init(_) do
    zookeeper_host = Application.fetch_env! :highlander, :zookeeper_host
    redis_host = Application.fetch_env! :highlander, :redis_host

    children = [
      worker(Zookeeper.Client, [zookeeper_host, [stop_on_disconnect: true, name: :zk]], []),
      worker(Highlander.Registry.Server, [], []),
      worker(Highlander.Registry.NodeCycleServer, [], []),
      worker(Redix, [redis_host, [name: :redix]], []),
      supervisor(Highlander.Object.Supervisor, [], [])
    ]

    supervise children, strategy: :rest_for_one
  end
end
