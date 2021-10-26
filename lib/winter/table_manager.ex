defmodule Winter.TableManager do
  @moduledoc false

  use Horde.DynamicSupervisor

  @spec start_link(any()) :: Supervisor.on_start()
  def start_link(args) do
    Horde.DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_) do
    Horde.DynamicSupervisor.init(strategy: :one_for_one, members: :auto)
  end

  @doc """
  Initiates a table, this table will be distributed among other nodes through this supervisor. Whether or not
  """
  @spec init_table(String.t()) :: DynamicSupervisor.on_start_child()
  def init_table(table_name) do
    Horde.DynamicSupervisor.start_child(__MODULE__, {Winter.Table, table_name: table_name})
  end
end
