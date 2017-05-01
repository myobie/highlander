defmodule Highlander do
  use Application

  def start(_type, _args) do
    Highlander.Supervisor.start_link
  end
end
