local M = {}

local Curl = require('plenary.curl')
local base64 = require('spotify.utils').base64

local data_path = vim.fn.stdpath('data')
local user_config = string.format('%s/spotify.json', data_path)

M.fetch_credentials = function()
  local refresh_token = vim.g['spotify-refresh-token']
  local client_id = vim.g['spotify-client-id']
  local client_secret = vim.g['spotify-client-secret']
  local requested_at = vim.g['spotify-token-requested-at']
  local expires_in = vim.g['spotify-token-expires-in']

  local delta = os.difftime((requested_at + expires_in), os.time())

  if delta > 0 then
    return true
  end

  Curl.post('https://accounts.spotify.com/api/token', {
    body = {
      grant_type = 'refresh_token',
      refresh_token = refresh_token
    },
    headers = {
      ['Content-Type'] = 'application/x-www-form-urlencoded',
      authorization = string.format('Basic %s', base64.encode(client_id .. ':' .. client_secret))
    },
    callback = function(res)
      if res.status == 200 then
        local body = vim.json.decode(res.body)

        local requested_at = os.time()

        local t = {
          expires_in = body.expires_in,
          requested_at = requested_at,
          access_token = body.access_token,
          refresh_token = vim.g['spotify-refresh-token']
        }

        vim.g['spotify-token'] = body.acess_token
        vim.g['spotify-token-requested-at'] = requested_at
        vim.g['spotify-token-expires-in'] = body.expires_in

        local data = vim.json.encode(t)

        local file, err = io.open(user_config, 'w')

        file:write(data)
        file:close()
      else
        print(vim.inspect(res))
      end
    end
  })
end

return M
