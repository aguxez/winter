defmodule Winter.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    cluster_children = check_distributed_flag()

    always_start = [
      {Horde.Registry, name: Horde.Registry.TableRegistry, keys: :unique, members: :auto},
      {Task.Supervisor, name: Winter.ReceptorTaskSupervisor},
      Winter.TableManager
    ]

    check_if_start = [
      Supervisor.child_spec({Task, fn -> Winter.Receptor.accept(receptor_port()) end},
        restart: :transient
      )
    ]

    children =
      case Application.get_env(:winter, :env) do
        :test -> always_start
        _ -> always_start ++ cluster_children ++ check_if_start
      end

    opts = [strategy: :one_for_one, name: Winter.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp receptor_port do
    :winter
    |> Application.get_env(:receptor_port)
    |> String.to_integer()
  end

  # Add Cluster.Supervisor children and config only if the distributed config is set
  defp check_distributed_flag do
    :winter
    |> Application.get_env(:is_distributed, false)
    |> build_cluster_config()
  end

  defp build_cluster_config(status) when status in [false, nil], do: []

  defp build_cluster_config(true) do
    topologies = Application.get_env(:libcluster, :topologies)
    [{Cluster.Supervisor, [topologies, [name: Winter.ClusterSupervisor]]}]
  end
end
