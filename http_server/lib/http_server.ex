defmodule HttpServer do
  use Application
  require Logger

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(__MODULE__, [1234])
    ]

    opts = [strategy: :one_for_one, name: HttpServer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def start_link(port) do
    pid = spawn_link fn ->
      Logger.info "Listening for requests on port #{port}"
      {:ok, socket} = :gen_tcp.listen(port,
        [:binary, packet: :line, active: false, reuseaddr: true])
      receive_connection_loop(socket)
    end
    {:ok, pid}
  end

  defp receive_connection_loop(socket) do
    case :gen_tcp.accept(socket) do
      {:ok, bound_socket} ->
        spawn fn -> HttpServer.Parser.start(bound_socket) end
      {:error, :closed} ->
        Logger.info "Client closed connection to #{inspect socket}"
    end
    receive_connection_loop(socket)
  end
end
