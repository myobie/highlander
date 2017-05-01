defmodule Highlander do
  use Application

  def start(_type, _args) do
    if Mix.env == :test do
      {:ok, _} = Highlanter.TestFileStore.start_link()
    end

    Highlander.Supervisor.start_link
  end
end
