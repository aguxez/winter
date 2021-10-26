FROM elixir:1.12.3-alpine as builder

ARG BUILD_ENV=prod

ENV MIX_ENV=${BUILD_ENV}

WORKDIR /opt

RUN mix local.rebar --force && mix local.hex --force

COPY . .

RUN mix do deps.get, compile
RUN mix release --overwrite
RUN mv _build/${BUILD_ENV}/rel/winter /opt/release
RUN mv /opt/release/bin/winter /opt/release/bin/server

########
FROM erlang:24.0.5-alpine

WORKDIR /opt/release

COPY --from=builder /opt/release .

ENTRYPOINT ["/opt/release/bin/server", "start"]
