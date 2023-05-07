local M = {}

local Curl = require('plenary.curl')

local player = require('spotify.player')

function M.get_playlists()
  local resp = Curl.get('https://api.spotify.com/v1/me/playlists', {
    query = {
      limit = 50
    },
    headers = {
      authorization = 'Bearer ' .. vim.g['spotify-token']
    }
  })

  if resp.status == 200 then
    return vim.json.decode(resp.body).items
  else
    return {}
  end
end

return M
