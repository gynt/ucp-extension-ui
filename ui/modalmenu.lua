--ui/modalmenu.lua

local api = api or {}
api.ui = api.ui or {}

if remote then
  _G.api = api
end

local game = game

if not remote then 
  game = require("ui.game")
end

local ffi = ffi
if not remote then
  ffi = modules.cffi:cffi()
end

local manager = manager
if remote then
   manager = remote.interface.manager
end

local ModalMenu = {}
api.ui.ModalMenu = ModalMenu

function ModalMenu:createModalMenu(params)
  local o = {}

  if params.modalMenuID == nil then
    error("no menu id")
  else
    o.modalMenuID = params.modalMenuID
  end

  if params.pointerToMenu == nil then
    error("no menu specified")
  else
    o.pointerToMenu = params.pointerToMenu
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
  if params.pMenuModalRenderFunction then
    o.pMenuModalRenderFunction = params.pMenuModalRenderFunction
  else
    o.menuModalRenderFunction = params.menuModalRenderFunction or function(x, y, width, height) end
    o.pMenuModalRenderFunction = ffi.cast("void (*)(int, int, int, int)", o.menuModalRenderFunction)
  end

  o.borderStyle = params.borderStyle or 512
  o.backgroundColor = params.backgroundColor or 0 -- TODO: is 0 illegal?

  o.x = params.x or -1
  o.y = params.y or -1

  o.modalMenuID = params.modalMenuID
  o.pModalMenu = ffi.new("MenuModal[1]", {})
  o.modalMenu = o.pModalMenu[0]

  game.UI.MenuModal(
    o.modalMenu, 
    o.modalMenuID,
    o.x,
    o.y,
    o.width,
    o.height,
    o.borderStyle,
    o.backgroundColour,
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