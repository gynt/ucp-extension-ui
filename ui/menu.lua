--ui/menu.lua

---@class UIAPI
---@field Menu Menu
---@field ModalMenu ModalMenu

---@class API
---@field ui UIAPI
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

---@class Menu
---@field pMenu number
local Menu = {}
api.ui.Menu = Menu

---@class MenuParams
---@field menuID number
---@field menuItemsCount number
---@field pPrepare number|nil
---@field pInitial number|nil
---@field pFrame number|nil
---@field prepare (fun():void)|nil
---@field initial (fun():void)|nil
---@field frame (fun():void)|nil


-- TODO: createMenu() should be passed the list of menu items to be created.
-- Because the Constructor_Menu() function already expects them to be present.
---@param params MenuParams
function Menu:createMenu(params)
  local o = {}

  if params.menuID == nil then
    error("no menu id")
  end

  local availableMenuID = manager.getAvailableMenuID(params.menuID)
  if availableMenuID ~= params.menuID then
    error(string.format("menu id not available: %s", params.menuID))
  end

  o.menuID = params.menuID

  o.pMenu = ffi.new("Menu[1]", {})
  ---@type struct_Menu
  o.menu = o.pMenu[0]
  o.pMenuView = ffi.new("struct MenuView[1]", {})
  o.menuView = o.pMenuView[0]

  
  o.menuItemsCount = params.menuItemsCount or 100
  o.menuItemsIndex = 0

  -- Adding the + 1 so the user doesn't need to know about the LAST_ENTRY
  ---@type table
  o.menuItems = ffi.new(string.format("MenuItem[%s]", o.menuItemsCount + 1), {}) -- TODO:, use [0] = {menuItemType = 0x66}

  for i=0,o.menuItemsCount do
    o.menuItems[i].menuItemType = 0x66 -- LAST_ENTRY  
    o.menuItems[i].menuPointer = ffi.nullptr
  end
  
  if params.pPrepare ~= nil then
    o.pPrepare = params.pPrepare
  else
    o.prepare = params.prepare or function() end
    o.pPrepare = ffi.cast("cdeclVoidFunc *", o.prepare)
  end
  
  if params.pInitial ~= nil then
    o.pInitial = params.pInitial
  else
    o.initial = params.initial or function() end
    o.pInitial = ffi.cast("cdeclVoidFunc *", o.initial)
  end
  
  if params.pFrame ~= nil then
    o.pFrame = params.pFrame
  else
    o.frame = params.frame or function() end
    o.pFrame = ffi.cast("cdeclVoidFunc *", o.frame)
  end
  
  game.UI.Menu(o.menu, o.menuItems)
  game.UI.MenuView(o.menuView, o.menuID, o.pPrepare, o.pInitial, o.pFrame)

  o = setmetatable(o, self)

  self.__index = self

  o:register()

  return o
end

local ffi_tonumber = ffi.tonumber or tonumber

function Menu:register()
  if self.pMenu == nil then error("menu is nil") end
  
  local addr = ffi_tonumber(ffi.cast("long", self.pMenu))
  if addr == nil then error("addr is nil") end
  return manager.registerMenu(addr, self.menuID)
end

function Menu:addMenuItem(params)
  if self.menuItemsIndex >= self.menuItemsCount then
    error("reached menu item limit")
  end

  local menuItem = self.menuItems[self.menuItemsIndex]
  menuItem.menuPointer = self.menu

  for k, v in pairs(params) do
    menuItem[k] = v
  end

  self.menuItemsIndex = self.menuItemsIndex + 1

  -- return self for chaining
  return self
end

if not remote then
  return api
end