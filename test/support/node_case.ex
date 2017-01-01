# Basically copied from <https://github.com/phoenixframework/phoenix_pubsub/blob/master/test/support/node_case.ex>

defmodule Highlander.Test.NodeCase do
  @timeout 500

  defmacro __using__(_opts) do
    quote do
      use ExUnit.Case, async: true
      import unquote(__MODULE__)
      @moduletag :clustered

      @timeout unquote(@timeout)
    end
  end

  # example using call_node from Phoenix
  # def start_tracker(node_name, opts) do
  #   call_node(node_name, fn -> start_tracker(opts) end)
  # end

  def flush do
    receive do
      _ -> flush
    after
      0 -> :ok
    end
  end

  defp call_node(node, func) do
    parent = self
    ref = make_ref

    pid = Node.spawn_link(node, fn ->
      result = func.()
      send parent, {ref, result}
      ref = Process.monitor(parent)
      receive do
        {:DOWN, ^ref, :process, _, _} -> :ok
      end
    end)

    receive do
      {^ref, result} -> {pid, result}
    after
      @timeout -> {pid, {:error, :timeout}}
    end
  end
end
