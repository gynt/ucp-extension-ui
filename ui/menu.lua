--ui/menu.lua

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

local Menu = {}
api.ui.Menu = Menu

-- TODO: createMenu() should be passed the list of menu items to be created.
-- Because the Constructor_Menu() function already expects them to be present.
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
  
  if params.pPrepare then
    o.pPrepare = params.pPrepare
  else
    o.prepare = params.prepare or function() end
    o.pPrepare = ffi.cast("cdeclVoidFunc *", o.prepare)
  end
  
  if params.pInitial then
    o.pInitial = params.pInitial
  else
    o.initial = params.initial or function() end
    o.pInitial = ffi.cast("cdeclVoidFunc *", o.initial)
  end
  
  if params.pFrame then
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