--ui/modalmenu.lua

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

local manager = _G.manager
if remote ~= nil then
   manager = remote.interface.manager
end

---@class ModalMenu
local ModalMenu = {}

---@type ModalMenu
api.ui.ModalMenu = ModalMenu

---@class ModalMenuParams
---@field modalMenuID number
---@field pointerToMenu number|nil
---@field menu Menu|nil
---@field width number
---@field height number
---@field x number
---@field y number
---@field pMenuModalRenderFunction number|nil
---@field menuModalRenderFunction (fun(x:number, y:number, width:number, height:number):void)|nil
---@field borderStyle number|nil
---@field backgroundColor number|nil

---@param params ModalMenuParams
function ModalMenu:createModalMenu(params)
  local o = {}

  if params.modalMenuID == nil then
    error("no menu id")
  else
    o.modalMenuID = params.modalMenuID
  end

  if params.pointerToMenu == nil and params.menu == nil then
    error("no menu specified")
  else
    if o.pointerToMenu ~= nil then
      o.pointerToMenu = params.pointerToMenu  
    elseif params.menu ~= nil then
      o.pointerToMenu = params.menu.pMenu
    else
      error("no menu specified")
    end
  end

  if params.width == nil then
    error("no width specified")
  else
    o.width = params.width
  end

  if params.height == nil then
    error("no height specified")
  else
    o.height = params.height
  end

  -- if params.menuModalRenderFunction == nil then
  --   error("no render function specified")
  -- end
  if params.pMenuModalRenderFunction ~= nil then
    if type(params.pMenuModalRenderFunction) == "number" then
      o.pMenuModalRenderFunction = ffi.cast("void (__cdecl *)(int, int, int, int)", params.pMenuModalRenderFunction)
    else
      o.pMenuModalRenderFunction = params.pMenuModalRenderFunction
    end
  else
    o.menuModalRenderFunction = params.menuModalRenderFunction or function(x, y, width, height) end
    o.pMenuModalRenderFunction = ffi.cast("void (__cdecl *)(int, int, int, int)", o.menuModalRenderFunction)
  end

  o.borderStyle = params.borderStyle or 512
  o.backgroundColor = params.backgroundColor or 0 -- TODO: is 0 illegal?

  o.x = params.x or -1
  o.y = params.y or -1

  o.modalMenuID = params.modalMenuID
  o.pModalMenu = ffi.new("struct MenuModal[1]", {})
  o.modalMenu = o.pModalMenu[0]

  game.UI.MenuModal(
    o.modalMenu, 
    o.modalMenuID,
    o.x,
    o.y,
    o.width,
    o.height,
    o.borderStyle,
    o.backgroundColor,
    o.pMenuModalRenderFunction,
    o.pointerToMenu
  )

  -- TODO: adjust from here to modal menus
 
  o = setmetatable(o, self)
  
  self.__index = self
  
  o:register()

  return o
end

function ModalMenu:register()
  -- This function is a dummy as creating a ModalMenu means automatically registering it as well
end