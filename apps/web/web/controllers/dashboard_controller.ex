defmodule Web.DashboardController do
  use Web.Web, :controller

  def index(conn, _params) do
    render conn, "index.html", csrf_token: get_csrf_token()
  end

  def nodes(conn, _params) do
    json conn, Domo.EventListener.Nodes.get
  end

  def node_command(conn, params) do
    IO.inspect(params)
    node_identifier = params["node_identifier"] |> String.to_existing_atom()
    if Domo.EventListener.Nodes.get |> Map.has_key?(node_identifier) do
      command = params["command"]
                |> List.replace_at(0, params["command"] |> List.first |> String.to_existing_atom())
                |> List.to_tuple
      GenServer.call(node_identifier, command)
      json conn, true
    else
      json conn, false
    end
  end

  def networks(conn, _params) do
    json conn, Domo.EventListener.Networks.get
  end

  def do_command(conn, params) do
    command = Domo.Node.get_commands(params["node"] |> String.to_existing_atom)
              |> Enum.find(fn([cmd_name | _rest]) -> cmd_name == params["command"] |> String.to_existing_atom end)

    [cmd_name | args] = command

    cmd_to_send = [cmd_name | args |> Enum.map(fn(arg) -> params[arg |> to_string] |> String.to_integer end)] |> List.to_tuple

    Process.send(params["node"] |> String.to_existing_atom, {:command, cmd_to_send}, [])

    redirect conn, to: "/"
  end
end
