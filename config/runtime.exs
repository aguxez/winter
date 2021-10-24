import Config

config :winter, receptor_port: System.get_env("RECEPTOR_PORT") || "6060"
