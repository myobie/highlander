defmodule HighlanderTest do
  require Logger
  use HighlanderTest.NodeCase, async: true
  alias Highlander.Object
  alias HighlanderTest.{User, Todo}
  doctest Highlander

  setup_all do
    # clear out all actors in the db
    Zookeeper.Client.delete :zk, "/__shared_objects__", -1, true
    Redix.command!(:redix, ~w(FLUSHDB))
    :ok
  end

  setup do
    {:ok, %{id: UUID.uuid4(), type: :user}}
  end

  test "can start user servers", %{id: id, type: type} do
    {:ok, pid} = Object.startup {type, id}
    {:ok, state} = Object.get_in_memory_state {type, id}
    assert state.id == id
    cleanup pid

    {:error, _} = Object.get_in_memory_state {type, id}
  end

  test "servers auto start when asked to do something", %{id: id, type: type} do
    {:ok, _} = Object.put_persisted_state {type, id}, %{"email" => "me@example.com"}

    pid = Object.lookup {type, id}
    assert is_pid(pid)

    {:ok, info} = Object.get_persisted_state {type, id}
    assert info["email"] == "me@example.com"
    cleanup pid

    nil = Object.lookup {type, id}

    {:ok, info} = Object.get_persisted_state {type, id}
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
    {:ok, _} = :rpc.call(@node2, Object, :put_persisted_state, [{type, id}, %{"email" => "me@example.com"}])

    # get_persisted_state the info here on primary
    {:ok, info} = Object.get_persisted_state {type, id}
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

  test "can create named objects", %{id: id} do
    {:ok, %{}} = User.get id

    {:ok, _} = User.put id, %{"name" => "Nathan"}

    {:ok, info} = User.get id

    {:ok, same_info} = Object.get_persisted_state {:user, id}

    assert info == same_info
  end

  test "can create objects that act like structs" do
    id = UUID.uuid4()

    {:ok, todo} = Todo.get id

    assert todo.completed == false
    assert todo.title == ""
    assert todo.color == :blue

    todo = %{todo | title: "Hello"}

    {:ok, _} = Todo.put id, todo

    {:ok, todo} = Todo.get id

    assert todo.title == "Hello"
  end
end
