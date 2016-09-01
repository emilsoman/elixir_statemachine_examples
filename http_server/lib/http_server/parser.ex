defmodule HttpServer.Parser do
  use GenStateMachine, callback_mode: :state_functions
  require Logger

  #### Public API ####

  # Given a socket with a client connection,
  # parses the HTTP message frame from the TCP packets
  # and sends a response echoing the request received
  def start(socket) do
    {:ok, pid} = GenStateMachine.start(__MODULE__, socket)
    GenStateMachine.cast(pid, {:parse_request_line, read_line_from_socket(socket)})
  end

  #### State machine callback implementation ####

  # This gets called when the state machine starts
  # Sets an initial state and data
  def init(socket) do
    {:ok, :started, socket}
  end

  def started(:cast, {:parse_request_line, request_line}, socket) do
    [method, uri, "HTTP/1.1"] = request_line |> String.trim |> String.split(" ")
    request = %{
      method: method,
      uri: uri,
      headers: %{}
    }

    {
      :next_state, :parsed_request_line, {socket, request},
      {:next_event, :internal, {:parse_header_line, read_line_from_socket(socket)}}
    }
  end

  def parsed_request_line(:internal, {:parse_header_line, "\r\n"}, {socket, request}) do
    {
      :next_state, :parsed_headers, {socket, request},
      {:next_event, :internal, :send_response}
    }
  end

  def parsed_request_line(:internal, {:parse_header_line, header_line}, {socket, request}) do
    [name, value] = header_line |> String.trim |> String.split(": ")
    request =  put_in(request, [:headers, name], value)

    {
      :keep_state, {socket, request},
      {:next_event, :internal, {:parse_header_line, read_line_from_socket(socket)}}
    }
  end

  def parsed_headers(:internal, :send_response, {socket, request}) do
    send_response_with_request_details(socket, request)
    :stop
  end


  #### Private functions below this line ####

  defp read_line_from_socket(socket) do
    {:ok, line} = :gen_tcp.recv(socket, 0)
    Logger.info "Received from socket (#{inspect socket}): #{inspect line}"
    line
  end

  defp send_response_with_request_details(socket, request) do
    body = inspect request
    message = """
    HTTP/1.1 200 OK
    Content-Type: text/plain
    Content-Length: #{String.length(body) + 1}

    #{body}
    """
    :gen_tcp.send(socket, message)
  end
end
