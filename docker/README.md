This was borrowed heavily from <https://github.com/lukeolbrish/examples/tree/master/zookeeper/five-server-docker>.

## Run all containers

```sh
docker-compose up -d
```

## To see logs

```sh
docker-compose logs
```

## Run a zookeepr cli

```sh
docker-compose run --rm zkcli -server zookeeper3
```

_There is an intro to zkcli here:
[Connecting To ZooKeeper](https://zookeeper.apache.org/doc/r3.4.8/zookeeperStarted.html#sc_ConnectingToZooKeeper)._
