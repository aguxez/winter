import Config

is_distributed = System.get_env("IS_DISTRIBUTED")

config :winter,
  receptor_port: System.get_env("RECEPTOR_PORT") || "6060",
  is_distributed: is_distributed

if is_distributed do
  config :libcluster,
    topologies: [
      winter_k8s: [
        strategy: Elixir.Cluster.Strategy.Kubernetes.DNS,
        config: [
          service: System.get_env("DNS_SERVICE_NAME"),
          application_name: System.get_env("DNS_APPLICATION_NAME")
        ]
      ]
    ]
end
