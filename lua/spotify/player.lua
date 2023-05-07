local M = {}

local Curl = require('plenary.curl')

M.set_volume = function(vol)
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
--
-- TODO: Colocar opção no require('spotify').setup({}) para definir os incrementos do volume
-- TODO: Armazenar volume direto em uma variável assim que iniciar o nvim, assim dá pra reduzir de execução do comando
M.increase_volume = function()
  local current_volume = M.get_playback_state().device.volume_percent

  M.set_volume(current_volume + 10)
end

M.decrease_volume = function()
  local current_volume = M.get_playback_state().device.volume_percent

  M.set_volume(current_volume - 10)
end

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
