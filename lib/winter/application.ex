defmodule Winter.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    cluster_config = check_distributed_flag()

    set_children = [
      {Task.Supervisor, name: Winter.ReceptorTaskSupervisor},
      {Horde.Registry, name: Horde.Registry.TableRegistry, keys: :unique, members: :auto},
      Supervisor.child_spec({Task, fn -> Winter.Receptor.accept(receptor_port()) end},
        restart: :transient
      ),
      Winter.TableManager
    ]

    children = cluster_config ++ set_children

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

  defp build_cluster_config(false), do: []

  defp build_cluster_config(true) do
    topologies = Application.get_env(:libcluster, :topologies)
    [{Cluster.Supervisor, [topologies, [name: Winter.ClusterSupervisor]]}]
  end
end
