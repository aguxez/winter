defmodule Winter.ReceptorTest do
  @moduledoc false

  use ExUnit.Case, async: true

  describe "accept/1" do
    setup [:start_server, :connect_socket, :get_password]

    test "refuses message when password configuration is set but no auth has been made", %{
      socket: socket
    } do
      msg = "CREATE table\r\n"
      :gen_tcp.send(socket, msg)
      assert_receive {:tcp, ^socket, "missing password\r\n"}, 500
    end

    test "accepts messages if auth is provided", %{socket: socket, password: password} do
      :gen_tcp.send(socket, "AUTH #{password}")

      assert_receive "ok\r\n"

      :gen_tcp.send(socket, "GET table key")
      refute_receive {:tcp, ^socket, "missing password\r\n"}, 500
    end
  end

  defp start_server(_) do
    spec =
      Supervisor.child_spec({Task, fn -> Winter.Receptor.accept(6060) end}, restart: :permanent)

    {:ok, pid} = start_supervised(spec)

    {:ok, pid: pid}
  end

  defp connect_socket(_) do
    {:ok, socket} = :gen_tcp.connect('127.0.0.1', 6060, [:binary, packet: :line, active: true])

    {:ok, socket: socket}
  end

  defp get_password(_), do: {:ok, password: Application.get_env(:winter, :conn_password)}
end
