defmodule Etcd.Utils do
  @moduledoc """
  Documentation for Etcd.Utils.
  """

  alias Etcd.Utils.{Options, Loader, KeyNotFoundError}

  @doc """
  Read from Etcd into Elixir map/array.

  ## Options

    * `:host` - Host to connect to. Default `"localhost"`
    * `:port` - Port to connect to. Default `2379`
    * `:root` - Where to dump load from. Default `"/"`
    * `:prefix` - Url prefix. Default `"/v2/keys"`

  ## Examples

      # Load everything from http://localhost:2379/v2/keys/
      Etcd.Utils.load

      # Load everything from http://localhost:2379/v2/keys/some/path
      Etcd.Utils.load(root: "/some/path")

      # Load everything from http://etcd.company.com:4001/v2/keys/some/path
      Etcd.Utils.load(host: "etcd.company.com", port: 4001, root: "/some/path")

  """
  def load(options \\ []) do
    Options.new(options) |> Loader.call
  end

  def flatten(map) do
    flatten(map, [])
  end

  def flatten(list, stack) when is_list(list) do
    list_to_map(list) |> flatten(stack)
  end

  def flatten(map, stack) do
    Enum.reduce map, %{}, fn {k, v}, acc ->
      stack = [k | stack]
      key = stack |> Enum.reverse |> Enum.join("/")
      acc = Map.put(acc, "/#{key}", v)
      cond do
        is_list(v) ->
          v = list_to_map(v)
          Map.merge(acc, flatten(v, stack))
        is_map(v) ->
          Map.merge(acc, flatten(v, stack))
        true ->
          acc
      end
    end
  end

  def dig!(map, path) when is_binary(path) do
    keys = path
      |> String.trim("/")
      |> String.split("/")
      |> Enum.map(&String.to_atom/1)
    dig!(map, keys)
  end

  def dig!(map, [key | rest]) do
    if Map.has_key?(map, key) do
      dig!(map[key], rest)
    else
      raise KeyNotFoundError, message: "key: #{key}"
    end
  end

  def dig!(value, []), do: value

  def dig(map, path, default \\ nil) do
    try do
      dig!(map, path)
    rescue
      KeyNotFoundError -> default
    end
  end

  def list_to_map(list) do
    padding = length(list) |> Integer.to_string |> String.length
    list |> Enum.with_index |> Enum.reduce(%{}, fn {item, i}, acc ->
      i = String.pad_leading("#{i}", padding+1, "0")
      Map.put(acc, i, item)
    end)
  end

end
