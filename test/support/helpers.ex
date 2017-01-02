defmodule HighlanderTest.Helpers do
  def alive?(pid) do
    on_node pid, Process, :alive?, [pid]
  end

  def exit(pid, reason \\ :shutdown) when is_pid(pid) do
    on_node pid, Process, :exit, [pid, reason]
  end

  def cleanup(pid) when is_pid(pid) do
    on_node pid, __MODULE__, :cleanup_locally, [pid]
  end

  def cleanup_locally(pid) when is_pid(pid) do
    Process.exit pid, :shutdown
    ref = Process.monitor pid
    receive do
      {:DOWN, ^ref, :process, _, _} -> :ok
    end
  end

  defp on_node(pid, module, fun, args \\ []) do
    me = Node.self
    case Kernel.node(pid) do
      :"nonode@nohost" ->
        raise "cannot find node the pid was created on"
      ^me -> apply(module, fun, args)
      node_name ->
        :rpc.call node_name, module, fun, args
    end
  end
end
