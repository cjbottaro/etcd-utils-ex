defmodule Etcd.Utils.Loader do

  def call(options) do
    http_response = HTTPoison.get!(url(options), [], params: [recursive: true])
    etcd_response = Poison.decode!(http_response.body)

    root_part = options.root
      |> String.trim_trailing("/")
      |> String.split("/")
      |> List.last
      |> String.to_atom

    case parse_node(etcd_response["node"]) do
      %{ ^root_part => value } -> value
      value -> value
    end
  end

  defp url(options) do
    path = "#{options.prefix}#{options.root}"
      |> String.replace(~r/\/+/, "/")
      |> String.trim_trailing("/")
    "http://#{options.host}:#{options.port}#{path}"
  end

  defp parse_node(%{"dir" => true} = node) do
    map = Enum.reduce node["nodes"], %{}, fn node, acc ->
      Map.merge(acc, parse_node(node))
    end

    obj = if is_array?(map) do
      arrayify(map)
    else
      map
    end

    if node["key"] do
      %{ key_part(node) => obj }
    else
      obj
    end
  end

  defp parse_node(node) do
    %{ key_part(node) => cast_value(node) }
  end

  defp is_array?(map) do
    Map.keys(map) |> Enum.all?(fn key ->
      key = Atom.to_string(key)
      Regex.match?(~r/^\d+$/, key)
    end)
  end

  defp arrayify(map) do
    Enum.into(map, [])
      |> Enum.sort_by(fn {index, _} -> index end)
      |> Enum.map(fn {_, value} -> value end)
  end

  defp key_part(node) do
    node["key"]
      |> String.split("/")
      |> List.last
      |> String.to_atom
  end

  defp cast_value(node) do
    value = node["value"] |> String.strip
    cond do
      value == "" -> nil
      Regex.match?(~r/^\d+$/, value) -> String.to_integer(value)
      Regex.match?(~r/^\d+\.\d+$/, value) -> String.to_float(value)
      true -> value
    end
  end
end
