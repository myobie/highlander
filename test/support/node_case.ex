# Basically copied from <https://github.com/phoenixframework/phoenix_pubsub/blob/master/test/support/node_case.ex>

defmodule HighlanderTest.NodeCase do
  @timeout 500
  @primary :"primary@127.0.0.1"
  @node1 :"node1@127.0.0.1"
  @node2 :"node2@127.0.0.1"

  defmacro __using__(_opts) do
    quote do
      use ExUnit.Case
      import unquote(__MODULE__)
      @moduletag :clustered

      @timeout unquote(@timeout)
      @primary unquote(@primary)
      @node1 unquote(@node1)
      @node2 unquote(@node2)
    end
  end

  def startup_user(node_name, id) do
    call_node(node_name, fn -> Highlander.Shared.User.startup(id) end)
  end

  def set_user_info(node_name, id, info) do
    call_node(node_name, fn -> Highlander.Shared.User.set_info(id, info) end)
  end

  def process_alive?(node_name, pid) when is_pid(pid) do
    call_node(node_name, fn -> Process.alive?(pid) end)
  end

  def cleanup_on_node(node_name, pid) do
    call_node(node_name, fn ->
      Process.exit pid, :shutdown
      ref = Process.monitor pid
      receive do
        {:DOWN, ^ref, :process, _, _} -> :ok
      end
    end)
  end

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

    Node.spawn_link(node, fn ->
      result = func.()
      send parent, {ref, result}
      ref = Process.monitor(parent)
      receive do
        {:DOWN, ^ref, :process, _, _} -> :ok
      end
    end)

    receive do
      {^ref, result} -> result
    after
      @timeout -> {:error, :timeout}
    end
  end
end
