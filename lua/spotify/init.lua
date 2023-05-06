local M = {}

local Menu = require('nui.menu')
local Input = require('nui.input')
local event = require('nui.utils.autocmd').event
local Curl = require('plenary.curl')
local Job = require('plenary.job')
local base64 = require('spotify.base64')

local data_path = vim.fn.stdpath('data')
local user_config = string.format('%s/spotify.json', data_path)

function M.play_track(track, album)
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

function M.enqueue_track(track)
  Curl.post('https://api.spotify.com/v1/me/player/queue', {
    query = {
      uri = track
    },
    headers = {
      authorization = 'Bearer ' .. vim.g['spotify-token']
    },
    callback = function() end
  })
end

function M.search_track(track)
  Curl.get('https://api.spotify.com/v1/search', {
    query = {
      q = track,
      type = 'track'
    },
    headers = {
      authorization = 'Bearer ' .. vim.g['spotify-token']
    },
    callback = function(res)
      vim.schedule(function()
        local bufnr = vim.api.nvim_create_buf(false, true)
        local tracks = {}
        local data = vim.json.decode(res.body)
        local t = {}
        for i, v in ipairs(data.tracks.items) do
          local item = Menu.item(string.format('%s - %s', v.artists[1].name, v.name),
            {
              play = function() M.play_track(v.uri) end,
              enqueue = function() M.enqueue_track(v.uri) end
            })
          table.insert(tracks, item)
        end

        local menu = Menu({
          relative = "editor",
          position = '50%',
          border = {
            style = "rounded",
            text = {
              top = "[SPOTIFY]",
              top_align = "center",
            },
          },
          win_options = {
            winhighlight = "Normal:Normal",
          }
        }, {
            lines = tracks,
            keymap = {
              submit = { '<CR>' },
              close = { 'q', '<ESC>', '<C-c>' }
            },
            on_submit = function(item)
              item.play()
            end
          })

        menu:map('n', 'a', function()
          (menu.tree:get_node()).enqueue()
        end)

        menu:mount()

        menu:on(event.BufLeave, function()
          menu:unmount()
        end)
      end)
    end
  })
end

function M.prompt()
  local input = Input({
    relative = 'editor',
    position = '50%',
    size = 20,
    border = {
      style = 'rounded',
      text = {
        top = '[Música]',
        top_align = 'center'
      }
    },
    win_options = {
      winhighlight = 'Normal:Normal'
    }},
    {
      prompt = '> ',
      on_submit = function(value)
        if value ~= '' then
          M.search_track(value)
        end
      end
    })

  input:map('n', 'q', function()
    input:unmount()
  end)

  input:map('n', '<ESC>', function()
    input:unmount()
  end)

  input:mount()

  input:on(event.BufLeave, function()
    input:unmount()
  end)
end

local function char_to_hex (c)
  return string.format("%%%02X", string.byte(c))
end

local function urlencode(url)
  if url == nil then
    return
  end
  url = url:gsub("\n", "\r\n")
  url = url:gsub("([^%w ])", char_to_hex)
  url = url:gsub(" ", "+")
  return url
end

local function fetch_credentials(refresh_token, old_credentials)
  local credentials = credentials

  Curl.post('https://accounts.spotify.com/api/token', {
    body = {
      grant_type = 'refresh_token',
      refresh_token = refresh_token
    },
    headers = {
      ['Content-Type'] = 'application/x-www-form-urlencoded',
      authorization = string.format('Basic %s', base64.encode(vim.g['spotify-client-id'] .. ':' .. vim.g['spotify-client-secret']))
    },
    callback = function(res)
      if res.status == 200 then
        local file, err = io.open(user_config, 'w')

        local body = vim.json.decode(res.body)

        credentials.requested_at = os.time()
        credentials.access_token = body.access_token
        credentials.expires_in = body.expires_in

        file:write(json.encode(credentials))
      else
        print(vim.inspect(res))
      end
    end
  })
end

function M.setup(opts)
  vim.g['spotify-client-id'] = opts.client_id
  vim.g['spotify-client-secret'] = opts.client_secret

  local file, err = io.open(user_config, 'r')

  if not err then
    local credentials = vim.json.decode(file:read('a'))
    local delta = os.difftime((credentials.requested_at + credentials.expires_in), os.time())
    local refresh_token = credentials.refresh_token

    if delta <= 0 then
      fetch_credentials(refresh_token, credentials)
    else
      vim.g['spotify-token'] = credentials.access_token
    end

    return true
  end

  local callback = urlencode(opts.callback)

  local url = 'https://accounts.spotify.com/authorize?client_id='.. vim.g['spotify-client-id'] ..'&response_type=code&redirect_uri='.. callback .. '&scope=user-modify-playback-state%20user-read-playback-state'

  local job = Job:new({
    command = 'ruby',
    args = {
      './server.rb',
      '-p',
      '3000',
      user_config
    },
    on_stderr = function(aa, j)
    end
  })

  job:start()

  print(string.format('Acesse %s para autorizar o plugin.', url))
end

return M
