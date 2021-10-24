defmodule Winter.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @port String.to_integer(System.get_env("RECEPTOR_PORT") || "6060")

  @impl true
  def start(_type, _args) do
    children = [
      Winter.TableManager,
      {Task.Supervisor, name: Winter.ReceptorSupervisor},
      {Registry, name: Registry.TableRegistry, keys: :unique},
      Supervisor.child_spec({Task, fn -> Winter.Receptor.accept(@port) end}, restart: :permanent)
    ]

    opts = [strategy: :one_for_one, name: Winter.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
