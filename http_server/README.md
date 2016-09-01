# HttpServer

This is a simple HTTP server that echoes the incoming requests.

## Usage

    $ mix deps.get
    $ iex -S mix

This starts the HTTP server on port 1234. Now use curl or browser (or any other HTTP client)
to send it a request.

    curl -v http://localhost:1234/foo/bar


States and events of the HTTP parser state machine:

```

              start
                +
                |
+---------------v----------------+
|                                |
|  State: :started               |
|  Data: socket                  |
|                                |
+---------------+----------------+
                |
                |  Event: :parse_request_line
                |
                |
+---------------v----------------+
|                                <--------+
|  State: :parsed_request_line   |        |
|  Data: socket, request         |        | Event: :parse_header_line
|                                +--------+
+---------------+----------------+
                |
                |  Event: :parse_header_line
                |
+---------------v----------------+
|                                |
|  State: :parsed_headers        |
|  Data: socket, request         |
|                                |
+---------------+----------------+
                |
                |  Event: :send_response
                v
              stop
```
