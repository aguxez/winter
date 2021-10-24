# Winter

Table based KV server

![](https://img.shields.io/badge/Made%20With-Elixir-blueviolet)
![](https://img.shields.io/badge/License-MIT-lightgray)

## Introduction

Winter is an in memory key-value store, the term table based comes from the idea that each group of data lives in isolation. If you want to PUT/GET/DELETE/etc... you must specify the table on which these commands are going to be actioned. Each table runs in a supervision tree which makes the server more responsive and reliable against application and network level errors.

## Building

Build the image from the Dockerfile and specify `RECEPTOR_PORT` AND `ENV` as part of the build configuration.

### Example

```bash
> docker build --build-arg RECEPTOR_PORT=4040 --build-arg BUILD_ENV=prod -t name:tag .
```

## Connecting

Connections happen through TCP. Open a connection to the specified `RECEPTOR_PORT` and you should be able to start sending commands.

## Supported Commands

All commands in this section, except for `CREATE` will also return a `missing table` message if the table hasn't been created

### CREATE `table`
Creates a new `table`

**Example**

```bash
> CREATE table
created

> CREATE table
already created
```

### GET `table` `key`

Gets `key` on `table`

**Example**

```bash
> GET table key
nil

> PUT table key data
ok

> GET table key
data
```


### PUT `table` `key` `data`
Puts `data` under `key` on `table`. This command is immutable.

**Example**

```bash
> PUT table key more data
ok

> PUT table key another chunk of data
ok

> GET table key
more data
```

### DELETE `table` `key`

Deletes `key` on `table`

**Example**

```bash
> PUT table key chunk
ok

> DELETE table key
ok

> GET table key
nil
```
