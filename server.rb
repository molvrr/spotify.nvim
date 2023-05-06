require 'json'
require 'base64'
require 'sinatra'
require 'httparty'

client_id = ENV['SMUDGE_CLIENT_ID']
client_secret = ENV['SMUDGE_CLIENT_SECRET']
encoded = Base64.strict_encode64("#{client_id}:#{client_secret}")

get '/spotify-nvim' do
  auth_code = params['code']

  resp = HTTParty.post('https://accounts.spotify.com/api/token',
                       body: {
                         code: auth_code,
                         redirect_uri: 'http://localhost:3000/spotify-nvim',
                         grant_type: 'authorization_code'
                       }, headers: {
                         'Authorization': "Basic #{encoded}"
                       })

  if resp.code == 200
    access_token = resp.parsed_response['access_token']
    expires_in = resp.parsed_response['expires_in']
    refresh_token = resp.parsed_response['refresh_token']

    File.open(ARGV.last, 'w') do |f|
      f.write({
        access_token: access_token,
        requested_at: Time.now.to_i,
        expires_in: expires_in,
        refresh_token: refresh_token
      }.to_json)
    end

  end

  200
end
