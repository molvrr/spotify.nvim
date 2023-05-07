local M = {}

local Curl = require('plenary.curl')

M.get_playback_state = function()
  local resp = Curl.get('https://api.spotify.com/v1/me/player', {
    headers = {
      authorization = 'Bearer ' .. vim.g['spotify-token']
    }
  })

  if resp.status == 200 then
    return vim.json.decode(resp.body)
  else
    return {}
  end
end

M.get_devices = function()
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

M.play_track = function(track)
  local devices = M.get_devices()
  local q = {}
  local b = {}

  if track.type == 'collection' then
    b = {
        context_uri = track.uri, -- album a tocar
        position_ms = 0
      }
  else
    b = {
      uris = { track.uri },
      position_ms = 0
    }
  end

  if devices[1] then
    Curl.put('https://api.spotify.com/v1/me/player/play', {
      query = q,
      body = vim.fn.json_encode(b),
      headers = {
        authorization = 'Bearer ' .. vim.g['spotify-token']
      },
      callback = function()
      end
    })
  else
    Curl.put('https://api.spotify.com/v1/me/player/play', {
      body = vim.fn.json_encode(b),
      headers = {
        authorization = 'Bearer ' .. vim.g['spotify-token']
      },
      callback = function()
      end
    })
  end
end

return M
