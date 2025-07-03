
local api = api or {}
api.ui = api.ui or {}

if remote ~= nil then
  _G.api = api
end

local game = game

if not remote then 
  game = require("ui.game")
end

---@type CFFIInterface
local ffi = ffi
if not remote then
  ffi = modules.cffi:cffi()
end