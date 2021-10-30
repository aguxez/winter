defmodule Winter.Table do
  @moduledoc """
  Handles communication between stores (or tables). Each process manages a different `store`.
  They're all kept in memory, these are managed by `Winter.TableManager`, so, in case of a crash
  then the process and the store itself will be automatically started.
  """

  use GenServer, restart: :transient

  @missing_table "missing table"
  @missing_password "missing password"

  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(table_name: table_name) do
    GenServer.start_link(__MODULE__, %{table_ref: table_name}, name: process_name(table_name))
  end

  @doc """
  Puts `data` under `key` on `table_name`.
  """
  @spec put_new(String.t(), String.t(), Port.t(), any(), Keyword.t()) ::
          String.t() | {:error, String.t()}
  def put_new(table_name, key, data, socket, opts \\ []) do
    case process_exists?(table_name) do
      {true, pid} -> GenServer.call(pid, {:put, key, data, socket, opts})
      _ -> {:error, @missing_table}
    end
  end

  @doc """
  Deletes `key` on `table_name`.
  """
  @spec delete(String.t(), String.t(), Port.t()) :: String.t() | {:error, String.t()}
  def delete(table_name, key, socket) do
    case process_exists?(table_name) do
      {true, pid} -> GenServer.call(pid, {:delete, key, socket})
      _ -> {:error, @missing_table}
    end
  end

  @doc """
  Gets `key` on `table_name`.
  """
  @spec get(String.t(), String.t(), Port.t()) :: any()
  def get(table_name, key, socket) do
    case process_exists?(table_name) do
      {true, pid} -> GenServer.call(pid, {:get, key, socket})
      _ -> {:error, @missing_table}
    end
  end

  @doc """
  Not exposed through the protocol. Checks if a given connection (socket) is authenticated against a table
  """
  @spec authenticated?(String.t(), Port.t()) :: boolean()
  def authenticated?(table, socket) do
    case process_exists?(table_name) do
      {true, pid} -> GenServer.call(pid, {:authenticated?, socket})
      _ -> {:error, @missing_table}
    end
  end

  @impl true
  def init(_) do
    table_ref = :ets.new(__MODULE__, write_concurrency: true, read_concurrency: true)
    {:ok, %{table_ref: table_ref, auths: %{}}}
  end

  @impl true
  def handle_call(
        {:put, key, data, socket, opts},
        _from,
        %{table_ref: table_ref, auths: auths} = state
      ) do
    ttl = Keyword.get(opts, :ttl)

    response =
      if is_authenticated(socket, auths) do
        :ets.insert_new(table_ref, {key, data})
        if ttl, do: Process.send_after(self(), {:ttl_delete, key}, ttl)
        "ok"
      else
        {:error, @missing_password}
      end

    {:reply, response, state}
  end

  @impl true
  def handle_call({:delete, key, socket}, _from, %{table_ref: table_ref, auths: auths} = state) do
    response =
      if is_authenticated(socket, auths) do
        :ets.delete(table_ref, key)
        "ok"
      else
        {:error, @missing_password}
      end

    {:reply, response, state}
  end

  @impl true
  def handle_call({:get, key, socket}, _from, %{table_ref: table_ref, auths: auths} = state) do
    response =
      with true <- is_authenticated(socket, auths),
           [{_, data}] <- :ets.lookup(table_ref, key) do
        data
      else
        false -> {:error, @missing_password}
        [] -> {:error, nil}
      end

    {:reply, response, state}
  end

  @impl true
  def handle_call({:authenticated?, socket}, _from, %{auths: auths} = state) do
    {:reply, is_authenticated(socket, auths), state}
  end

  @impl true
  def handle_info({:ttl_delete, key}, %{table_ref: table_ref} = state) do
    :ets.delete(table_ref, key)
    {:noreply, state}
  end

  defp process_name(name), do: {:via, Horde.Registry, {Horde.Registry.TableRegistry, name}}

  defp process_exists?(table_name) do
    process_pid =
      table_name
      |> process_name()
      |> GenServer.whereis()

    {!!process_pid, process_pid}
  end

  # Checks if socket is authenticated against this table. A table can hold many auths but a single connection
  # holds a single auth, acts as a user
  defp is_authenticated(socket, auths), do: !!Map.get(auths, socket)
end
