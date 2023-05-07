local Curl = require('plenary.curl')
local auth = require('spotify.auth')

local M = {}

M.auth_funcs = {}
M.funcs = {}

M.__index = function(tbl, k)
  local auth_func = M.auth_funcs[k]
  local func = M.funcs[k]

  if auth_func then
    auth.fetch_credentials()

    return auth_func
  end

  return func
end

setmetatable(M, M)

M.auth_funcs.set_volume = function(vol)
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
end

-- TODO: Colocar opção no require('spotify').setup({}) para definir os incrementos do volume
-- NOTE: Talvez armazenar o valor em uma variável possa ser um problema caso o usuário atualize o volume diretamente na UI do Spotify
-- TODO: |- Pensar em uma forma de sincronizar
M.auth_funcs.increase_volume = function(inc)
  if not vim.g['spotify-volume'] then
    vim.g['spotify-volume'] = M.get_playback_state().device.volume_percent
  end

  vim.g['spotify-volume'] = vim.g['spotify-volume'] + inc

  M.set_volume(vim.g['spotify-volume'])
end

M.auth_funcs.decrease_volume = function(dec)
  if not vim.g['spotify-volume'] then
    vim.g['spotify-volume'] = M.get_playback_state().device.volume_percent
  end

  vim.g['spotify-volume'] = vim.g['spotify-volume'] - dec

  M.set_volume(vim.g['spotify-volume'])
end

M.auth_funcs.get_playback_state = function()
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

M.auth_funcs.get_devices = function()
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

-- TODO: Memoize no dispositivo atual para que a interface fique responsiva
M.auth_funcs.play_track = function(track)
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
