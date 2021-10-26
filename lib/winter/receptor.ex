defmodule Winter.Receptor do
  @moduledoc """
  Main interface to manage TCP connections.
  """

  require Logger

  alias Winter.Command

  @doc """
  Starts receiving connections on the specified `port`.
  """
  @spec accept(non_neg_integer()) :: no_return()
  def accept(port) do
    case :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true]) do
      {:ok, socket} ->
        Logger.info("Accepting connections on port #{port}")

        loop_receptor(socket)

      {:error, _} ->
        self()
    end
  end

  defp loop_receptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)

    Logger.info("Received a connection on socket #{inspect(socket)}")

    {:ok, pid} =
      Task.Supervisor.start_child(Winter.ReceptorTaskSupervisor, fn ->
        serve(client)
      end)

    :gen_tcp.controlling_process(client, pid)
    loop_receptor(socket)
  end

  defp serve(socket) do
    socket
    |> read_line()
    |> Command.handle()
    |> write_line(socket)

    serve(socket)
  end

  defp read_line(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} -> data
      {:error, _} -> ""
    end
  end

  defp write_line([_ | _] = responses, socket) do
    Enum.each(responses, fn response ->
      :gen_tcp.send(socket, response <> "\n")
    end)
  end

  defp write_line(response, socket), do: :gen_tcp.send(socket, response <> "\n")
end
