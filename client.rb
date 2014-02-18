require 'faye/websocket'
require 'eventmachine'
require 'json'
require 'openssl'

CLIENT_ID = 1
VERSION = 1
SERVER_KEY = OpenSSL::PKey::RSA.new File.read('public_key.pem')
cipher = OpenSSL::Cipher::AES.new(256, :CBC)
cipher.encrypt
session_key = cipher.random_key
session_iv = cipher.random_iv
ticket = nil
EM.run {
  ws = Faye::WebSocket::Client.new('ws://127.0.0.1:9292')
  encrypted_session = SERVER_KEY.public_encrypt(session_key)

  ws.on :open do |event|
    p [:open]
    ws.send([VERSION, Base64.encode64(encrypted_session), Base64.encode64(session_iv), CLIENT_ID].to_json)
  end

  ws.on :message do |event|
    p [:message, event.data]
    unless ticket
      ticket = event.data
      puts "Assigned ticket #"+ticket
    else
      decipher = OpenSSL::Cipher::AES.new(256, :CBC)
      decipher.decrypt
      decipher.key = session_key
      decipher.iv = session_iv
      token = decipher.update(Base64.decode64(event.data)) + decipher.final
      puts "TOKEN: " + token
    end
  end

  ws.on :close do |event|
    p [:close, event.code, event.reason]
    session_key = nil
    ws = nil
    exit
  end
}
