defmodule Winter.Receptor do
  @moduledoc false

  require Logger

  def accept(port) do
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

    Logger.info("Accepting connections on port #{port}")
    loop_receptor(socket)
  end

  defp loop_receptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(Winter.ReceptorSupervisor, fn ->
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
    {:ok, data} = :gen_tcp.recv(socket, 0)
    String.trim(data)
  end

  defp handle_request("PUT " <> rest) do
    [key, data] = String.split(rest, " ", parts: 2)
    Winter.Table.put("table", key, data)
    "ok\n"
  end

  defp handle_request("GET " <> key) do
    Winter.Table.get("table", key) <> "\n"
  end

  defp handle_request("DELETE " <> key) do
    Winter.Table.delete("table", key)
    "ok\n"
  end

  defp handle_request(_), do: "unrecognized command\n"

  defp write_line(response, socket) do
    :gen_tcp.send(socket, response)
  end
end
