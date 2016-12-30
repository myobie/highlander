defmodule Highlander.Shared.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link __MODULE__, [], name: __MODULE__
  end

  def init(_) do
    children = [
      supervisor(Highlander.Shared.User.Supervisor, [], [])
      # ... other shared object supervisors
    ]

    supervise children, [strategy: :one_for_one]
  end
end
