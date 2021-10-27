defmodule Winter.CommandTest do
  @moduledoc false

  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Winter.Command

  describe "handle" do
    # the idea of this test is not to handle commands exactly but other
    # clauses
    property "correctly handles different inputs" do
      check all(command <- string(:ascii, min_length: 1)) do
        # This is kinda defeating the purpose of the PBT but for different kind of inputs
        # we do some conversion on the code which we need here as that's interpolated in the response string
        [command | _] =
          command
          |> String.trim_leading()
          |> String.trim_trailing()
          |> String.split(" ", parts: 2)

        assert Command.handle(command) in ["", "unrecognized command #{command}"]
      end
    end
  end

  describe "handle/CREATE" do
    property "properly handles command" do
      check all(
              command <- one_of([constant("CREATE ")]),
              table <- string(:alphanumeric, min_length: 3)
            ) do
        assert Command.handle(command <> table) == "created"
      end
    end
  end

  describe "handle/PUTNEW" do
    setup [:set_table_name_and_keys, :create_table]

    test "it does not override an already set value", %{
      table_name: table_name,
      key: key,
      value: value
    } do
      assert Command.handle("PUTNEW #{table_name} #{key} #{value}") == "ok"
      assert Winter.Table.get(table_name, key) == value

      Command.handle("PUTNEW #{table_name} #{key} different data")
      assert Winter.Table.get(table_name, key) == value
    end
  end

  describe "handle/GET" do
    setup [:set_table_name_and_keys, :create_table, :put_value]

    property "handles missing and existing values", %{table_name: table, key: key, value: value} do
      check all(
              table <- one_of([constant(table), string(:ascii, min_length: 2)]),
              key <- one_of([constant(key), binary(min_length: 2)])
            ) do
        assert Command.handle("GET #{table} #{key}") in ["nil", "missing table", value]
      end
    end
  end

  describe "handle/DELETE" do
    setup [:set_table_name_and_keys, :create_table, :put_value]

    test "deletes a value from a table", %{table_name: table, key: key} do
      assert Command.handle("DELETE #{table} #{key}") == "ok"
      assert Command.handle("GET #{table} #{key}") == "nil"
    end

    test "returns error if table is missing" do
      assert Command.handle("DELETE missing key") == "missing table"
    end
  end

  defp set_table_name_and_keys(_) do
    [table_name, key, value] =
      :alphanumeric
      |> string(min_length: 2)
      |> Enum.take(3)

    {:ok, table_name: table_name, key: key, value: value}
  end

  defp create_table(ctx) do
    Command.handle("CREATE #{ctx.table_name}")
    :ok
  end

  defp put_value(ctx) do
    Command.handle("PUTNEW #{ctx.table_name} #{ctx.key} #{ctx.value}")
    :ok
  end
end
