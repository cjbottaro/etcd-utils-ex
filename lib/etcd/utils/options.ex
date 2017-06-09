defmodule Etcd.Utils.Options do

  defstruct [
    host: "localhost",
    port: 2379,
    prefix: "/v2/keys",
    root: "/",
    redirect_limit: 2,
    index_padding: 1,
    cast_values: true,
  ]

  def new(options \\ []) do
    options = Application.get_all_env(:etcd_utils)
      |> Keyword.merge(options)
    struct(__MODULE__, options)
  end

end
