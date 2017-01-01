# Highlander

A project to create the primitives for creating object oriented distributed systems.

_There can be only one_ object for each object ID ever at a time.

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

When you are finished you can terminate all containers with:

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
