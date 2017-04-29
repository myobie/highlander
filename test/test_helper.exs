exclude = Keyword.get(ExUnit.configuration(), :exclude, [])

defmodule HighlanderTest.User do
  use Highlander.Object, type: :user
end

defmodule HighlanderTest.Todo do
  use Highlander.Object, type: :todo

  defobject title: "", completed: false, color: :blue
end

cond do
  :clustered in exclude ->
    ExUnit.start()
  true ->
    HighlanderTest.Cluster.spawn()
    ExUnit.start()
end
