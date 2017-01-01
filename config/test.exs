use Mix.Config

config :highlander, zookeeper_host: "127.0.0.1:2181"

config :highlander, :spawn_nodes, [:"node1@127.0.0.1", :"node2@127.0.0.1"]
