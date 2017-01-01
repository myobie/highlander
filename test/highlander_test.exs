defmodule HighlanderTest do
  require Logger
  use HighlanderTest.NodeCase
  doctest Highlander

  setup do
    # clear out all actors in the db
    Zookeeper.Client.delete :zk, "/__shared_objects__", -1, true
    # stop actor id 1 if it's running
    case Highlander.Shared.User.lookup("1") do
      pid when is_pid(pid) -> Process.exit(pid, :shutdown)
      _ -> nil
    end

    Logger.debug "setup done"

    :ok
  end

  def cleanup(pid) when is_pid(pid) do
    Process.exit pid, :shutdown
    ref = Process.monitor pid
    assert_receive {:DOWN, ^ref, :process, _, _}
    refute Process.alive?(pid)
  end

  test "is connected to zookeeper" do
    {:ok, list} = Zookeeper.Client.get_children :zk, "/"
    assert list == ["zookeeper"]
  end

  test "can start user servers" do
    {:ok, pid} = Highlander.Shared.User.startup "1"
    {:ok, state} = Highlander.Shared.User.get_in_memory_state "1"
    assert state.id == "1"
    cleanup pid

    {:error, _} = Highlander.Shared.User.get_in_memory_state "1"
  end

  test "servers auto start when asked to do something" do
    {:ok, _} = Highlander.Shared.User.set_info "1", %{email: "me@example.com"}

    pid = Highlander.Shared.User.lookup "1"
    assert is_pid(pid)

    {:ok, info} = Highlander.Shared.User.get_info "1"
    assert info.email == "me@example.com"
    cleanup pid

    nil = Highlander.Shared.User.lookup "1"

    {:ok, info} = Highlander.Shared.User.get_info "1"
    assert info.email == "me@example.com"

    pid = Highlander.Shared.User.lookup "1"
    assert is_pid(pid)
    cleanup pid
  end

  test "cannot create two servers for the same user id" do
    {:ok, pid} = Highlander.Shared.User.startup "1"

    {:error, _msg} = Highlander.Shared.User.startup "1"

    assert Process.alive?(pid)
    cleanup pid
  end

  test "can start a server on a seperate node" do
    # start a user on node1
    {:ok, pid} = startup_user @node1, "1"
    assert process_alive?(@node1, pid)

    assert pid == Highlander.Shared.User.lookup("1")

    # set the info over on node2
    {:ok, _} = set_user_info(@node2, "1", %{email: "me@example.com"})

    # get the info here on primary
    {:ok, info} = Highlander.Shared.User.get_info "1"
    assert info.email == "me@example.com"

    cleanup_on_node @node1, pid
  end

  test "cannot create two servers for the same user id on two different nodes" do
    {:ok, pid} = startup_user @node1, "1"
    assert process_alive?(@node1, pid)

    assert pid == Highlander.Shared.User.lookup("1")

    {:error, _msg} = startup_user @node2, "1"

    assert pid == Highlander.Shared.User.lookup("1")

    cleanup_on_node @node1, pid
  end
end
