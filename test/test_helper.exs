exclude = Keyword.get(ExUnit.configuration(), :exclude, [])

cond do
  :clustered in exclude ->
    ExUnit.start()
  true ->
    Highlander.Test.Cluster.spawn()
    ExUnit.start()
end
