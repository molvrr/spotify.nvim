local Curl = require('plenary.curl')
local Menu = require('nui.menu')
local event = require('nui.utils.autocmd').event
local player = require('spotify.player')
local authenticate = require('spotify.auth').authenticate

local M = {}

M.enqueue_track = authenticate(function(track)
  Curl.post('https://api.spotify.com/v1/me/player/queue', {
    query = {
      uri = track
    },
    headers = {
      authorization = 'Bearer ' .. vim.g['spotify-token']
    },
    callback = function(res)
      if res.status == 204 then
        print('Música enfileirada com sucesso!')
      end
    end
  })
end)

M.search_track = authenticate(function(track)
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
              play = function() player.play_track({ uri = v.uri, type = 'track' }) end,
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
end)

return M
