local M = {}

local function char_to_hex (c)
  return string.format("%%%02X", string.byte(c))
end

function M.urlencode(url)
  if url == nil then
    return
  end
  url = url:gsub("\n", "\r\n")
  url = url:gsub("([^%w ])", char_to_hex)
  url = url:gsub(" ", "+")
  return url
end

return M
