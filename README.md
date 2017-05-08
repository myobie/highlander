# Highlander

A prototype project to create the primitives for creating object oriented distributed systems.

_There can be only one_ object for each object ID at a time.

## Should I use this?

Probably not. This is a proof-of-concept for a crazy idea and hasn't been
proved in production yet. I think a library like this should exist and I am
willing to work towards getting this idea into production in time.

## Features

This project currently has too many responsibilities and should probably become three different libraries:

* GenPersistedServer to persist `state` after updates
* ZookeeperRegistry to host the process registry in zk
* Highlander which would tie it together and provide the "object" macros to make creating applications easier

## History

### Why not use `:global`?

`:global` is great and is the MVP of cluster-wide process ids. It, however, is
known to allow a "split brain" during a network partition. This is not a bad
thing: maybe you don't mind having two of something for a short time.

<http://erlang.org/doc/man/global.html> explains about "name clashes" and the
`Resolve` function. If it were consistent, then there would be no need for a
`Resolve`.

### Why not use `:pg2`?

`:pg2` is explicitly not consistent and is pretty much `AP`, which can be a
great thing. It also allows you to have a process under multiple ids and an id
point at multiple processes.

Check out <http://erlang.org/pipermail/erlang-questions/2012-June/067220.html>
where it says:

> pg2 replicates all name lookup information in a way that doesn’t require
> consistency

### Why not use `Registry`?

Registry is great and Highlander should use it instead of it's own internal
state map for the on-node lookups. The problem is that Registry is not a
multi-node solution. For a single node, it's really good.

### What about `:gproc`?

So, I think it's not consistent. Read
<https://christophermeiklejohn.com/erlang/2013/06/05/erlang-gproc-failure-semantics.html>
where it says:

> While gproc has been tested very thoroughly … its reliance on gen_leader is problematic.

I honestly don't know why there are so many negative articles about
`gen_leader`, but it does seem like there is not community support for it being
the correct solution to this problem. I don't know. I intend to write my own
experiments with `gen_leader` to learn about it, but I have not had time.

### What about `riak_core`?

Sure. I am sure one can use `riak_*` to achieve something similar, but I don't think it's wise for me to head down that road yet. I'd love to see someone do that.

## Setup

### Docker

You must have `docker`, `docker-compose`, and be able to `$ docker ps`.

Then you must be running all the necessary containers in the `./docker` folder with `docker-compose`:

```sh
$ cd docker
$ docker-compose up -d
```

You can get to the logs of the containers with:

```sh
$ docker-compose logs
```

When you are finished developing or running tests you can terminate all
containers with:

```sh
$ docker-compose down
```

### Elixir

You must have elixir, erlang, etc installed.

Then install the necessary dependencies:

```sh
$ mix deps.get
```

## Tests

```sh
$ epmd -daemon # to allow port mappings and things
$ mix test
```
