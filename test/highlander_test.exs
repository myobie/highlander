defmodule HighlanderTest do
  require Logger
  use ExUnit.Case
  doctest Highlander

  setup do
    # clear out all actors in the db
    Zookeeper.Client.delete :zk, "/__shared_objects__", -1, true
    # stop actor id 1 if it's running
    case Highlander.Shared.User.lookup("1") do
      pid when is_pid(pid) -> Process.exit(pid, :shutdown)
      _ -> nil
    end

    :ok
  end

  test "is connected to zookeeper" do
    {:ok, list} = Zookeeper.Client.get_children :zk, "/"
    assert list == ["zookeeper"]
  end

  test "can start user servers" do
    {:ok, pid} = Highlander.Shared.User.startup "1"
    {:ok, state} = Highlander.Shared.User.get_in_memory_state "1"
    assert state.id == "1"

    Process.exit pid, :shutdown
    ref = Process.monitor pid
    assert_receive {:DOWN, ^ref, _, _, _}
    refute Process.alive?(pid)

    {:error, _} = Highlander.Shared.User.get_in_memory_state "1"
  end

  test "servers auto start when asked to do something" do
    {:ok, _} = Highlander.Shared.User.set_info "1", %{email: "me@example.com"}

    pid = Highlander.Shared.User.lookup "1"
    assert is_pid(pid)

    {:ok, info} = Highlander.Shared.User.get_info "1"
    assert info.email == "me@example.com"

    Process.exit pid, :shutdown
    ref = Process.monitor pid
    assert_receive {:DOWN, ^ref, _, _, _}
    refute Process.alive?(pid)

    nil = Highlander.Shared.User.lookup "1"

    {:ok, info} = Highlander.Shared.User.get_info "1"
    assert info.email == "me@example.com"

    pid = Highlander.Shared.User.lookup "1"
    assert is_pid(pid)

    Process.exit pid, :shutdown
    ref = Process.monitor pid
    assert_receive {:DOWN, ^ref, _, _, _}
    refute Process.alive?(pid)
  end

  test "cannot create two servers for the same user id" do
    {:ok, pid} = Highlander.Shared.User.startup "1"

    {:error, _msg} = Highlander.Shared.User.startup "1"

    assert Process.alive?(pid)

    Process.exit pid, :shutdown
    ref = Process.monitor pid
    assert_receive {:DOWN, ^ref, _, _, _}
    refute Process.alive?(pid)
  end
end
