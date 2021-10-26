defmodule Winter.Table do
  @moduledoc """
  Handles communication between stores (or tables). Each process manages a different `store`.
  They're all kept in memory, these are managed by `Winter.TableManager`, so, in case of a crash
  then the process and the store itself will be automatically started.
  """

  use GenServer, restart: :transient

  @missing_table "missing table"

  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(table_name: table_name) do
    GenServer.start_link(__MODULE__, table_name, name: process_name(table_name))
  end

  @doc """
  Puts `data` under `key` on `table_name`.
  """
  @spec put(String.t(), String.t(), any()) :: String.t()
  def put(table_name, key, data) do
    case process_exists?(table_name) do
      {true, pid} ->
        GenServer.cast(pid, {:put, key, data})
        "ok"

      _ ->
        @missing_table
    end
  end

  @doc """
  Deletes `key` on `table_name`.
  """
  @spec delete(String.t(), String.t()) :: String.t()
  def delete(table_name, key) do
    case process_exists?(table_name) do
      {true, pid} ->
        GenServer.cast(pid, {:delete, key})
        "ok"

      _ ->
        @missing_table
    end
  end

  @doc """
  Gets `key` on `table_name`.
  """
  @spec get(String.t(), String.t()) :: any()
  def get(table_name, key) do
    case process_exists?(table_name) do
      {true, pid} -> GenServer.call(pid, {:get, key})
      _ -> @missing_table
    end
  end

  @impl true
  def init(_) do
    table_ref = :ets.new(__MODULE__, write_concurrency: true, read_concurrency: true)
    {:ok, table_ref}
  end

  @impl true
  def handle_cast({:put, key, data}, table_ref) do
    :ets.insert_new(table_ref, {key, data})
    {:noreply, table_ref}
  end

  @impl true
  def handle_cast({:delete, key}, table_ref) do
    :ets.delete(table_ref, key)
    {:noreply, table_ref}
  end

  @impl true
  def handle_call({:get, key}, _from, table_ref) do
    response =
      case :ets.lookup(table_ref, key) do
        [{_, data}] -> data
        [] -> nil
      end

    {:reply, response, table_ref}
  end

  defp process_name(name), do: {:via, Horde.Registry, {Horde.Registry.TableRegistry, name}}

  defp process_exists?(table_name) do
    process_pid =
      table_name
      |> process_name()
      |> GenServer.whereis()

    {!!process_pid, process_pid}
  end
end
