# Winter

## KV database server

Build the image from the Dockerfile and specify `RECEPTOR_PORT` AND `ENV` as part of the build configuration.

### Example

```bash
> docker build --build-arg RECEPTOR_PORT=4040 --build-arg ENV=prod -t name:tag .
```

### Connecting

Connections happen through TCP. Open a connection to the specified `RECEPTOR_PORT` and you should be able to start sending commands.

* Accepts common commands LIKE `PUT store key data`, `GET store key` AND `DELETE store key`.
