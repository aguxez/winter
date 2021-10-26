<h1 align="center">Winter</h1>

<p align="center"><img src="https://user-images.githubusercontent.com/17911679/138747087-301b4eeb-4e26-45c5-8c70-5eec97444d5c.png" alt="logo" width="200"/></p>

<p align="center">Distributed table based KV server</p>

<p align="center"><img src="https://img.shields.io/badge/Made%20With-Elixir-blueviolet"/> <img src="https://img.shields.io/badge/License-MIT-lightgray"/></p>

## Introduction

Winter is a distributed in memory key-value store, the term table based comes from the idea that each group of data lives in isolation. If you want to PUT/GET/DELETE/etc... you must specify the table on which these commands are going to be actioned. Each table runs in a supervision tree which makes the server more responsive and reliable against application and network level errors.

## Building

Build the image from the Dockerfile and specify `BUILD_ENV` as part of the build configuration.

Then specify `RECEPTOR_PORT` when running it.

### Example

```bash
> docker build --build-arg BUILD_ENV=prod -t name:tag .

> docker run -e RECEPTOR_PORT=1010 -it name:tag

## Alternatively, you can pull it from the hub
> docker pull aguxez/winter:latest
```

## Connecting

Connections happen through TCP. Open a connection to the specified `RECEPTOR_PORT` and you should be able to start sending commands.

## Supported Commands

<details>
  <summary>Click to show</summary>

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

  > PUTNEW table key data
  ok

  > GET table key
  data
  ```


  ### PUTNEW `table` `key` `data`
  Puts `data` under `key` on `table`. This command is immutable.

  **Example**

  ```bash
  > PUTNEW table key more data
  ok

  > PUTNEW table key another chunk of data
  ok

  > GET table key
  more data
  ```

  ### DELETE `table` `key`

  Deletes `key` on `table`

  **Example**

  ```bash
  > PUTNEW table key chunk
  ok

  > DELETE table key
  ok

  > GET table key
  nil
  ```
</details>

## Distributed workload
<details>
<summary>Click to show</summary>

  Winter can work as a distributed deployment if you wish to do so, based on a toggle (`IS_DISTRIBUTED=true`) at startup, Winter will set the necessary configuration. At this moment Winter only works with Kubernetes through DNS configuration. You have to set two env vars for this to work properly if `IS_DISTRIBUTED=true`

  * `DNS_SERVICE_NAME`
  * `DNS_APPLICATION_NAME`

  In the `k8s` folder you can see an example configuration (which can be easily deployed to `minikube`) and in that example `DNS_SERVICE_NAME=winter-nodes` and `DNS_APPLICATION_NAME=winter`.

  Nodes discovery/removal works automatically by default.
</details>

### TODO

- [ ] More friendly configuration so we can abstract the need to know Elixir for distributed workload.
