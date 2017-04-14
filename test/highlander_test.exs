defmodule HighlanderTest do
  require Logger
  use HighlanderTest.NodeCase, async: true
  alias Highlander.Shared.User
  doctest Highlander

  setup_all do
    # clear out all actors in the db
    Zookeeper.Client.delete :zk, "/__shared_objects__", -1, true
  end

  setup do
    {:ok, %{user_id: UUID.uuid4}}
  end

  test "can start user servers", %{user_id: user_id} do
    {:ok, pid} = User.startup user_id
    {:ok, state} = User.get_in_memory_state user_id
    assert state.id == user_id
    cleanup pid

    {:error, _} = User.get_in_memory_state user_id
  end

  test "servers auto start when asked to do something", %{user_id: user_id} do
    {:ok, _} = User.set_info user_id, %{"email" => "me@example.com"}

    pid = User.lookup user_id
    assert is_pid(pid)

    {:ok, info} = User.get_info user_id
    assert info["email"] == "me@example.com"
    cleanup pid

    nil = User.lookup user_id

    {:ok, info} = User.get_info user_id
    assert info["email"] == "me@example.com"

    pid = User.lookup user_id
    assert is_pid(pid)
    cleanup pid
  end

  test "cannot create two servers for the same user id", %{user_id: user_id} do
    {:ok, pid} = User.startup user_id

    {:error, _msg} = User.startup user_id

    assert alive?(pid)
    cleanup pid
  end

  test "can start a server on a seperate node", %{user_id: user_id} do
    # start a user on node1
    {:ok, pid} = User.startup user_id, node: @node1
    assert alive?(pid)

    assert pid == User.lookup(user_id)

    # set the info over on node2
    {:ok, _} = :rpc.call(@node2, User, :set_info, [user_id, %{"email" => "me@example.com"}])

    # get the info here on primary
    {:ok, info} = User.get_info user_id
    assert info["email"] == "me@example.com"

    cleanup pid
  end

  test "cannot create two servers for the same user id on two different nodes", %{user_id: user_id} do
    {:ok, pid} = User.startup user_id, node: @node1
    assert alive?(pid)

    assert pid == User.lookup(user_id)

    {:error, _msg} = User.startup user_id, node: @node2
    {:error, _msg} = User.startup user_id, node: @primary

    assert pid == User.lookup(user_id)

    cleanup pid
  end
end
