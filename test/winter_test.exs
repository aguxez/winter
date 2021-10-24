defmodule WinterTest do
  use ExUnit.Case
  doctest Winter

  test "greets the world" do
    assert Winter.hello() == :world
  end
end
