import Config

config :stream_data, max_runs: if(System.get_env("CI")), do: 500, else: 25
