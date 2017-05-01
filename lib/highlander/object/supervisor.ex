defmodule Highlander.Object.Supervisor do
  use Supervisor
  alias Highlander.Object.Server

  def start_link do
    Supervisor.start_link __MODULE__, [], name: __MODULE__
  end

  def init(_) do
    children = [
      worker(Server, [], [restart: :transient])
    ]

    supervise children, strategy: :simple_one_for_one
  end
end
