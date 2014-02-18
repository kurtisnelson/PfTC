require 'openssl'
require 'json'
require 'base64'
require 'faraday'
require 'pry'

unless File.exists? 'private_key.pem' and File.exists? 'public_key.pem'
  key = OpenSSL::PKey::RSA.new 2048
  open 'private_key.pem', 'w' do |io|
    io.write key.to_pem
  end
  open 'public_key.pem', 'w' do |io|
    io.write key.public_key.to_pem
  end
end

SERVER_KEY = OpenSSL::PKey::RSA.new File.read 'private_key.pem'

puts "What is your ticket #?"
ticket_num = gets.to_i

conn = Faraday.new(url: "http://127.0.0.1:9292", ssl: {verify: false})
data = conn.get "/#{ticket_num}"
data = JSON.parse(data.body)
encrypted_session = Base64.decode64(data["encrypted_session"])
cipher = OpenSSL::Cipher::AES.new(256, :CBC)
cipher.encrypt
cipher.key = SERVER_KEY.private_decrypt(encrypted_session)
cipher.iv = Base64.decode64(data["iv"])

puts "What is the token you want to pass?"
token = gets.chomp
enc_token = Base64.encode64(cipher.update(token) + cipher.final)

resp = conn.post do |req|
  req.url "/#{ticket_num}"
  req.headers['Content-Type'] = 'application/json'
  req.body = {token: enc_token}.to_json
end
