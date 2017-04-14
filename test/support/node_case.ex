# Basically copied from <https://github.com/phoenixframework/phoenix_pubsub/blob/master/test/support/node_case.ex>

defmodule HighlanderTest.NodeCase do
  @primary :"primary@127.0.0.1"
  @node1 :"node1@127.0.0.1"
  @node2 :"node2@127.0.0.1"

  defmacro __using__(opts) do
    quote do
      use ExUnit.Case, unquote(opts)
      import unquote(__MODULE__)
      import HighlanderTest.Helpers
      @moduletag :clustered

      @primary unquote(@primary)
      @node1 unquote(@node1)
      @node2 unquote(@node2)
    end
  end
end
