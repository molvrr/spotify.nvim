local M = {}

local base64 = require('spotify.utils.base64')

local char_to_hex = function(c)
  return string.format("%%%02X", string.byte(c))
end

M.urlencode = function(url)
  if url == nil then
    return
  end
  url = url:gsub("\n", "\r\n")
  url = url:gsub("([^%w ])", char_to_hex)
  url = url:gsub(" ", "+")
  return url
end

return M
