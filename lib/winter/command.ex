defmodule Winter.Command do
  @moduledoc """
  Entrypoint for handling commands
  """

  alias Winter.{Table, TableManager}

  @eol "\r\n"

  @doc """
  Handles a set of commands and functionality.
  """
  @spec handle(String.t()) :: String.t() | [String.t()]
  def handle(command) do
    case check_pipelined(command) do
      {true, commands} -> Enum.map(commands, &do_handle/1)
      {false, @eol} -> do_handle("")
      {false, command} -> do_handle(command)
    end
  end

  defp do_handle("CREATE " <> table_name) do
    case TableManager.init_table(table_name) do
      {:ok, _pid} -> "created"
      {:error, {:already_started, _pid}} -> "already created"
    end
  end

  defp do_handle("PUTNEW " <> rest) do
    [store, key, data] = String.split(rest, " ", parts: 3)
    {data, ttl} = extract_ttl(data)
    Table.put_new(store, key, data, ttl: ttl)
  end

  defp do_handle("GET " <> rest) do
    [store, key] = String.split(rest, " ", parts: 2)

    case Table.get(store, key) do
      nil -> "nil"
      data -> data
    end
  end

  defp do_handle("DELETE " <> rest) do
    [store, key] = String.split(rest, " ", parts: 2)
    Table.delete(store, key)
  end

  defp do_handle(""), do: <<>>

  defp do_handle(input) do
    [command | _] =
      input
      |> String.trim_leading()
      |> String.trim_trailing()
      |> String.split(" ", parts: 2)

    "unrecognized command #{command}"
  end

  # A Pipelined command should come as follows (GET a_table key\r\nPUTNEW table key data\r\nPING\r\n)
  # so if the split returns a single item it means we're processing a single command
  defp check_pipelined(command) do
    case String.split(command, :binary.compile_pattern(["\\r\\n", "\r\n"]), trim: true) do
      [command] -> {false, command}
      [] -> {false, ""}
      commands -> {true, commands}
    end
  end

  # In case the command has a TTL we're going to take it out and leave the data to put behind
  defp extract_ttl(command_input) do
    case String.split(command_input, " EXPIRE ", parts: 2) do
      [data] -> {data, nil}
      [data, ttl] -> {data, String.to_integer(ttl)}
    end
  end
end
