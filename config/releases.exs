import Config

config :winter,
  conn_password: System.get_env("CONN_PASSWORD")
