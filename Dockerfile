FROM elixir:1.12.3-alpine as builder

ARG ENV=prod

WORKDIR /opt

RUN mix local.rebar --force && mix local.hex --force

COPY . .

RUN mix do deps.get, compile \
  && mix release --overwrite \
  && mv _build/${ENV}/rel/winter /opt/release \
  && mv /opt/release/bin/winter /opt/release/bin/server

########
FROM erlang:24.0.5-alpine

WORKDIR /opt/release

ARG RECEPTOR_PORT

COPY --from=builder /opt/release .

EXPOSE ${RECEPTOR_PORT}

CMD ["/opt/release/bin/server", "start"]
