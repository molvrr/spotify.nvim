local Menu = require('nui.menu')
local Input = require('nui.input')
local event = require('nui.utils.autocmd').event
local Curl = require('plenary.curl')
local Job = require('plenary.job')
local base64 = require('spotify.utils').base64
local tracks = require('spotify.tracks')
local auth = require('spotify.auth')

local urlencode = require('spotify.utils').urlencode

local data_path = vim.fn.stdpath('data')
local user_config = string.format('%s/spotify.json', data_path)

local prompt = function()
  local input = Input({
    relative = 'editor',
    position = '50%',
    size = 20,
    border = {
      style = 'rounded',
      text = {
        top = '[Spotify]',
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
          tracks.search_track(value)
        end
      end
    })

  input:map('n', 'q', function()
    input:unmount()
  end)

  input:map('n', '<ESC>', function()
    input:unmount()
  end)

  input:on(event.BufLeave, function()
    input:unmount()
  end)

  input:mount()
end

local setup = function(opts)
  vim.g['spotify-client-id'] = opts.client_id
  vim.g['spotify-client-secret'] = opts.client_secret

  local file, err = io.open(user_config, 'r')

  if not err then
    local credentials = vim.json.decode(file:read('a'))
    local delta = os.difftime((credentials.requested_at + credentials.expires_in), os.time())
    vim.g['spotify-refresh-token'] = credentials.refresh_token
    vim.g['spotify-token'] = credentials.access_token
    vim.g['spotify-token-expires-in'] = credentials.expires_in
    vim.g['spotify-token-requested-at'] = credentials.requested_at

    if delta <= 0 then
      auth.fetch_credentials()
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

return {
  prompt = prompt,
  setup = setup,
}
