require 'rack'
require 'thin'
require 'eventmachine'
require 'faye/websocket'
require 'json'

class Session < Faye::WebSocket
  attr_reader :ticket
  attr_accessor :key
  attr_accessor :iv
  attr_accessor :metadata
  def initialize(ticket, env)
    @ticket = ticket
    super env
  end
end

Faye::WebSocket.load_adapter 'thin'

ticket_counter = 0
web_sockets = []

App = lambda do |env|
  if Faye::WebSocket.websocket? env
    ws = web_sockets[ticket_counter] = Session.new(ticket_counter, env)
    ticket_counter += 1
    puts "Used ticket ##{ws.ticket}"

    ws.on :message do |event|
      ws.send(ws.ticket)
      data = JSON.parse(event.data)
      ws.key = data[1]
      ws.iv = data[2]
      if data.length > 4
        ws.metadata = data[4..-1]
      end
    end

    ws.on :close do |event|
      p [:close, event.code, event.reason]
      ws = nil
    end

    ws.rack_response
  else
    req = Rack::Request.new(env)
    ticket_number = req.path[1..-1]
    session = web_sockets[ticket_number.to_i]
    return [404, {'Content-Type' => 'text/plain'}, ["Not Found"]] unless session
    if req.get?
      return [200, {'Content-Type' => 'application/json'}, [{encrypted_session: session.key, iv: session.iv, metadata: session.metadata}.to_json]]
    elsif req.post?
      data = JSON.parse(req.body.read)
      session.send(data["token"])
      session.close
      return [200, {'Content-Type' => 'text/plain'}, [env]]
    end
    [404, {'Content-Type' => 'text/plain'}, [env]]
  end
end

EM.run {
  thin = Rack::Handler.get 'thin'
  thin.run(App, Port: 9292) do |server|
    server.ssl_options = {
    }
    server.ssl = false
  end
}
