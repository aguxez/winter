defmodule Winter.Receptor do
  @moduledoc """
  Main interface to manage TCP connections.
  """

  require Logger

  alias Winter.{Table, TableManager}

  @doc """
  Starts receiving connections on the specified `port`.
  """
  @spec accept(non_neg_integer()) :: no_return()
  def accept(port) do
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

    Logger.info("Accepting connections on port #{port}")
    loop_receptor(socket)
  end

  defp loop_receptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)

    Logger.info("Received a connection on socket #{inspect(socket)}")

    {:ok, pid} =
      Task.Supervisor.start_child(Winter.ReceptorSupervisor, fn ->
        serve(client)
      end)

    :gen_tcp.controlling_process(client, pid)
    loop_receptor(socket)
  end

  defp serve(socket) do
    socket
    |> read_line()
    |> handle_request()
    |> write_line(socket)

    serve(socket)
  end

  defp read_line(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} -> String.trim(data)
      {:error, _} -> ""
    end
  end

  defp handle_request("CREATE " <> table_name) do
    case TableManager.init_table(table_name) do
      {:ok, _pid} -> "created"
      {:error, {:already_started, _pid}} -> "already created"
    end
  end

  defp handle_request("PUT " <> rest) do
    [store, key, data] = String.split(rest, " ", parts: 3)
    Table.put(store, key, data)
  end

  defp handle_request("GET " <> rest) do
    [store, key] = String.split(rest, " ", parts: 2)

    case Table.get(store, key) do
      nil -> "nil"
      data -> data
    end
  end

  defp handle_request("DELETE " <> rest) do
    [store, key] = String.split(rest, " ", parts: 2)
    Table.delete(store, key)
  end

  defp handle_request(""), do: <<>>

  defp handle_request(input) do
    [command | _] = String.split(input, " ", parts: 2)

    "unrecognized command #{command}"
  end

  defp write_line(response, socket) do
    :gen_tcp.send(socket, response <> "\n")
  end
end
