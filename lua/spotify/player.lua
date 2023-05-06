local M = {}

local Curl = require('plenary.curl')

function M.get_devices()
  local resp = Curl.get('https://api.spotify.com/v1/me/player/devices', {
    headers = {
      authorization = 'Bearer ' .. vim.g['spotify-token']
    }
  })

  if resp.status == 200 then
    return vim.json.decode(resp.body).devices
  else
    return {}
  end
end

function M.play_track(track, album)
  local devices = M.get_devices()

  local q = {}

  if devices[1] then
    Curl.put('https://api.spotify.com/v1/me/player/play', {
      query = q,
      body = vim.fn.json_encode({
        -- context_uri = '', -- album a tocar
        uris = {track},
        position_ms = 0
      }),
      headers = {
        authorization = 'Bearer ' .. vim.g['spotify-token']
      },
      callback = function()
      end
    })
  else
    Curl.put('https://api.spotify.com/v1/me/player/play', {
      body = vim.fn.json_encode({
        -- context_uri = '', -- album a tocar
        uris = {track},
        position_ms = 0
      }),
      headers = {
        authorization = 'Bearer ' .. vim.g['spotify-token']
      },
      callback = function()
      end
    })
  end
end

return M
