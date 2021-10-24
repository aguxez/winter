defmodule Winter.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Winter.TableManager,
      {Task.Supervisor, name: Winter.ReceptorSupervisor},
      {Registry, name: Registry.TableRegistry, keys: :unique},
      Supervisor.child_spec({Task, fn -> Winter.Receptor.accept(receptor_port()) end},
        restart: :permanent
      )
    ]

    opts = [strategy: :one_for_one, name: Winter.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp receptor_port do
    :winter
    |> Application.get_env(:receptor_port)
    |> String.to_integer()
  end
end
