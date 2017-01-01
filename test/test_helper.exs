exclude = Keyword.get(ExUnit.configuration(), :exclude, [])

cond do
  :clustered in exclude ->
    ExUnit.start()
  true ->
    HighlanderTest.Cluster.spawn()
    ExUnit.start()
end
