defmodule HighlanderTest do
  require Logger
  use HighlanderTest.NodeCase, async: true
  alias Highlander.Object
  doctest Highlander

  setup_all do
    # clear out all actors in the db
    Zookeeper.Client.delete :zk, "/__shared_objects__", -1, true
  end

  setup do
    {:ok, %{id: UUID.uuid4, type: :user}}
  end

  test "can start user servers", %{id: id, type: type} do
    {:ok, pid} = Object.startup {type, id}
    {:ok, state} = Object.get_in_memory_state {type, id}
    assert state.id == id
    cleanup pid

    {:error, _} = Object.get_in_memory_state {type, id}
  end

  test "servers auto start when asked to do something", %{id: id, type: type} do
    {:ok, _} = Object.put {type, id}, %{"email" => "me@example.com"}

    pid = Object.lookup {type, id}
    assert is_pid(pid)

    {:ok, info} = Object.get {type, id}
    assert info["email"] == "me@example.com"
    cleanup pid

    nil = Object.lookup {type, id}

    {:ok, info} = Object.get {type, id}
    assert info["email"] == "me@example.com"

    pid = Object.lookup {type, id}
    assert is_pid(pid)
    cleanup pid
  end

  test "cannot create two servers for the same user id", %{id: id, type: type} do
    {:ok, pid} = Object.startup {type, id}

    {:error, _msg} = Object.startup {type, id}

    assert alive?(pid)
    cleanup pid
  end

  test "can start a server on a seperate node", %{id: id, type: type} do
    # start a user on node1
    {:ok, pid} = Object.startup {type, id}, node: @node1
    assert alive?(pid)

    assert pid == Object.lookup({type, id})

    # set the info over on node2
    {:ok, _} = :rpc.call(@node2, Object, :put, [{type, id}, %{"email" => "me@example.com"}])

    # get the info here on primary
    {:ok, info} = Object.get {type, id}
    assert info["email"] == "me@example.com"

    cleanup pid
  end

  test "cannot create two servers for the same user id on two different nodes", %{id: id, type: type} do
    {:ok, pid} = Object.startup {type, id}, node: @node1
    assert alive?(pid)

    assert pid == Object.lookup({type, id})

    {:error, _msg} = Object.startup {type, id}, node: @node2
    {:error, _msg} = Object.startup {type, id}, node: @primary

    assert pid == Object.lookup({type, id})

    cleanup pid
  end
end
