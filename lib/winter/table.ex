defmodule Winter.Table do
  @moduledoc """
  Handles communication between stores (or tables). Each process manages a different `store`.
  They're all kept in memory, these are managed by `Winter.TableManager`, so, in case of a crash
  then the process and the store itself will be automatically started.
  """

  use GenServer, restart: :transient

  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(table_name: table_name) do
    GenServer.start_link(__MODULE__, table_name, name: process_name(table_name))
  end

  @doc """
  Puts `data` under `key` on `table_name`.
  """
  @spec put(String.t(), String.t(), any()) :: :ok
  def put(table_name, key, data) do
    table_name
    |> process_name()
    |> GenServer.cast({:put, key, data})
  end

  @doc """
  Deletes `key` on `table_name`.
  """
  @spec delete(String.t(), String.t()) :: :ok
  def delete(table_name, key) do
    table_name
    |> process_name()
    |> GenServer.cast({:delete, key})
  end

  @doc """
  Gets `key` on `table_name`.
  """
  @spec get(String.t(), String.t()) :: any()
  def get(table_name, key) do
    table_name
    |> process_name()
    |> GenServer.call({:get, key})
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
        [] -> ""
      end

    {:reply, response, table_ref}
  end

  defp process_name(name), do: {:via, Registry, {Registry.TableRegistry, name}}
end
