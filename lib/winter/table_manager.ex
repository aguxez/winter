defmodule Winter.TableManager do
  @moduledoc false

  use DynamicSupervisor

  @spec start_link(any()) :: Supervisor.on_start()
  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @spec init_table(String.t()) :: DynamicSupervisor.on_start_child()
  def init_table(table_name) do
    DynamicSupervisor.start_child(__MODULE__, {Winter.Table, table_name: table_name})
  end
end
