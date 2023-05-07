local M = {}

-- TODO: Escrever algo tipo I18n
-- TODO: Separar UI da lógica
-- TODO: Todas requisições pra api precisam chamar o fetch_credentials para garantir que as credenciais estão atualizadas

local Menu = require('nui.menu')
local Input = require('nui.input')
local event = require('nui.utils.autocmd').event
local Curl = require('plenary.curl')
local Job = require('plenary.job')
local base64 = require('spotify.base64')
local tracks = require('spotify.tracks')

local urlencode = require('spotify.utils').urlencode

local data_path = vim.fn.stdpath('data')
local user_config = string.format('%s/spotify.json', data_path)

function M.prompt()
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

  input:mount()

  input:on(event.BufLeave, function()
    input:unmount()
  end)
end

local function fetch_credentials(refresh_token, old_credentials)
  local credentials = old_credentials

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
        local file, err = io.open(user_config, 'r')

        local body = vim.json.decode(res.body)

        credentials.requested_at = os.time()
        credentials.access_token = body.access_token
        credentials.expires_in = body.expires_in

        vim.g['spotify-token'] = credentials.access_token

        local data = vim.json.encode(credentials)

        local file, err = io.open(user_config, 'w')

        file:write(data)
        file:close()
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
      '3000', -- TODO: Pegar porta de opts
      user_config
    },
    on_stderr = function(aa, j)
    end
  })

  job:start()

  print(string.format('Acesse %s para autorizar o plugin.', url))
end

return M
