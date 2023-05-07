local Curl = require('plenary.curl')
local authenticate = require('spotify.auth').authenticate

local get_playback_state = authenticate(function()
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
end)

local transfer_playback = authenticate(function(device)
  Curl.put('https://api.spotify.com/v1/me/player', {
    headers = {
      authorization = 'Bearer ' .. vim.g['spotify-token']
    },
    body = vim.json.encode({
      device_ids = { device },
      play = true
    })
  })
end)

local set_volume = authenticate(function(vol)
  Curl.put('https://api.spotify.com/v1/me/player/volume', {
    headers = {
      authorization = 'Bearer ' .. vim.g['spotify-token']
    },
    query = {
      volume_percent = vol % 101
    },
    callback = function(res)
      if res.status == 204 then
        print(string.format('Volume: %d%%', vol))
      else
        print('Erro ao atualizar volume')
      end
    end
  })
end)

local increase_volume = authenticate(function(inc)
  if not vim.g['spotify-volume'] then
    vim.g['spotify-volume'] = get_playback_state().device.volume_percent
  end

  vim.g['spotify-volume'] = vim.g['spotify-volume'] + inc

  set_volume(vim.g['spotify-volume'])
end)

local decrease_volume = authenticate(function(dec)
  if not vim.g['spotify-volume'] then
    vim.g['spotify-volume'] = get_playback_state().device.volume_percent
  end

  vim.g['spotify-volume'] = vim.g['spotify-volume'] - dec

  set_volume(vim.g['spotify-volume'])
end)

local get_devices = authenticate(function()
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
end)

local play_track = authenticate(function(track)
  local devices = get_devices()
  local b = {}

  if track.type == 'collection' then
    b = {
      context_uri = track.uri,
      position_ms = 0
    }
  else
    b = {
      uris = { track.uri },
      position_ms = 0
    }
  end

  if devices[1] then
    if not devices[1].is_active then
      transfer_playback(devices[1].id)
    end

    Curl.put('https://api.spotify.com/v1/me/player/play', {
      body = vim.fn.json_encode(b),
      headers = {
        authorization = 'Bearer ' .. vim.g['spotify-token']
      },
      callback = function()
      end
    })
  end
end)

return {
  decrease_volume = decrease_volume,
  get_devices = get_devices,
  get_playback_state = get_playback_state,
  increase_volume = increase_volume,
  play_track = play_track,
  set_volume = set_volume,
}
