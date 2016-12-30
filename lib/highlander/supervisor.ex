defmodule Highlander.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link __MODULE__, [], name: __MODULE__
  end

  def init(_) do
    host = Application.fetch_env! :highlander, :zookeeper_host

    children = [
      worker(Zookeeper.Client, [host, [stop_on_disconnect: true, name: :zk]], []),
      worker(Highlander.Registry.Server, [], []),
      worker(Highlander.Shared.Info.Server, [], []),
      supervisor(Highlander.Shared.Supervisor, [], [])
    ]

    supervise children, strategy: :rest_for_one
  end
end
