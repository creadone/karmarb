module Karma
  class Connection
    def initialize
      @maxlen = 4096
    end

    def send_and_read(request)
      unless defined?(@socket)
        establish_connection!
      end
      send(request)
      read
    end

    private

    def connect
      begin
        yield @socket
      rescue => e
        establish_connection!
        retry
      end
    end

    def send(message)
      message = message.to_json
      connect do |conn|
        conn.send("#{message}\r\n", 0)
        conn.flush
      end
    end

    def read
      connect do |conn|
        response = conn.recv(@maxlen)
        begin
          OpenStruct.new(JSON.parse(response))
        rescue => e
          return OpenStruct.new({
            "success" => false,
            "response" => e.message
          })
        end
      end
    end

    def establish_connection!
      @socket = TCPSocket.new(
        Karma.configuration.host,
        Karma.configuration.port,
        connect_timeout: 0.5
      )
    end

  end
end