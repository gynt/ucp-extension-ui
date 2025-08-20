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
  ---@diagnostic disable-next-line: assign-type-mismatch
  ---@type cffi
  local cffi = modules.cffi
  ffi = cffi:cffi()
end

---@type Manager
local manager 
if remote ~= nil then
  manager = remote.interface.manager
else
  manager = require("manager")
end

---@class Menu
---@field pMenu table<struct_Menu>
---@field menu struct_Menu
---@field menuID number
---@field pMenuView table<MenuView>
---@field menuView MenuView
---@field menuItemsCount number
---@field menuItems table<MenuItem>
---@field pPrepare number
---@field pInitial number
---@field pFrame number
---@field prepare (fun():void)
---@field initial (fun():void)
---@field frame (fun():void)
---
local Menu = {}
api.ui.Menu = Menu

---@class MenuParams
---@field menuID number
---@field menuItemsCount number|nil
---@field menuItems table<MenuItem>|nil
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
  ---@diagnostic disable-next-line: missing-fields
  ---@type Menu
  local o = {}

  if params.menuID == nil then
    error("no menu id")
  end

  local availableMenuID = manager.getAvailableMenuID(params.menuID)
  if availableMenuID ~= params.menuID then
    error(string.format("menu id not available: %s", params.menuID))
  end

  o.menuID = params.menuID

  ---@type table<struct_Menu>
  o.pMenu = ffi.new("Menu[1]", {})
  o.menu = o.pMenu[0]
  o.pMenuView = ffi.new("struct MenuView[1]", {})
  o.menuView = o.pMenuView[0]

  if params.menuItemsCount ~= nil then
    o.menuItemsCount = params.menuItemsCount  
    o.menuItemsIndex = 0
    -- Adding the + 1 so the user doesn't need to know about the LAST_ENTRY
    ---@type table
    o.menuItems = ffi.new(string.format("MenuItem[%s]", o.menuItemsCount + 1), {})
      
    for i=0,o.menuItemsCount do
      o.menuItems[i].menuItemType = 0x66 -- LAST_ENTRY  
      o.menuItems[i].menuPointer = ffi.nullptr
    end

  elseif params.menuItems ~= nil then
    ---@type table
    o.menuItems = params.menuItems -- Assumes the user took care of the final entry...
    o.menuItemsCount = ffi.sizeof(o.menuItems) / ffi.sizeof("MenuItem")
    o.menuItemsIndex = o.menuItemsCount
  else
    error("no menu items specified")
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

---@param pointer number|table<struct_Menu>
---@param menuID number
function Menu:fromPointer(pointer, menuID)

  if menuID == nil then error("no menu id given") end

  ---@type struct_Menu
  local menu
  if type(pointer) == "number" then
    pointer = ffi.cast("Menu *", pointer)
  end
  menu = pointer[0]
 

  ---@type table<MenuItem>
  local menuItemsArray = menu.menuItemArray
  local i = 0
  while menuItemsArray[i].menuItemType ~= 0x66 do
    i = i + 1
  end

  log(VERBOSE, string.format("Menu:fromPointer(0x%X, 0x%X): has %d menu items", ffi_tonumber(ffi.cast("unsigned long", pointer)), menuID, i))

  ---@type Menu
  local o = {
    menuID = menuID,
    menu = menu,
    pMenu = pointer,
    pMenuView = nil,
    menuView = nil,
    menuItemsCount = i,
    menuItemsIndex = i, -- TODO: meant to signal the menu item array is full, does this work?
    menuItems = menuItemsArray,
  }
  
  o = setmetatable(o, self)
  self.__index = self
  return o
end

function Menu:fromID(menuID)
  return Menu:fromPointer(manager.lookupMenu(menuID), menuID)
end

function Menu:register()
  if self.pMenu == nil then error("menu is nil") end
  
  local addr = ffi_tonumber(ffi.cast("long", self.pMenu))
  if addr == nil then error("addr is nil") end
  registerObject(self)
  return manager.registerMenu(addr, self.menuID)
end

function Menu:reallocateMenuItems()
  log(VERBOSE, "Menu:reallocateMenuItems()")
  local newCount = self.menuItemsCount * 2
  
  local newMenuItems
  local status, err = pcall(function()
    newMenuItems = ffi.new(string.format("struct MenuItem[%d]", newCount), {}) -- TODO: dynamic multiplication parameter?
  end)
  if status == false then error(err) end

  log(VERBOSE, string.format("Menu:reallocateMenuItems: rellocating menu items from 0x%X (%d) to 0x%X (%d)", 
    ffi_tonumber(ffi.cast("unsigned long", self.menuItems)), 
    self.menuItemsCount, 
    ffi_tonumber(ffi.cast("unsigned long", newMenuItems)), 
    newCount))

  for i=0,self.menuItemsCount do
    newMenuItems[i].menuItemType = 0x66 -- LAST_ENTRY  
    newMenuItems[i].menuPointer = ffi.nullptr
  end

  ffi.copy(newMenuItems, self.menuItems, self.menuItemsCount * ffi.sizeof("struct MenuItem"))

  --- If the array had been allocated with luajit e.g. via Menu:createMenu, then it will be garbage collected soon!
  self.menuItems = newMenuItems
  self.menuItemsCount = newCount

  self.menu.menuItemArray = newMenuItems

  --- TODO: increment index?
end

function Menu:insertMenuItem(index, params)
  if self.menuItemsIndex >= self.menuItemsCount then
    self:reallocateMenuItems()
  end

  --- TODO: needs testing...
  log(VERBOSE, "Menu:insertMenuItem: copying items")
  for i=self.menuItemsIndex,index,-1 do
    self.menuItems[i+1] = self.menuItems[i]
  end

  log(VERBOSE, "Menu:insertMenuItem: clearing original item")
  ffi.fill(self.menuItems[index], ffi.sizeof("MenuItem", 1), 0)

  log(VERBOSE, "Menu:insertMenuItem: setting new item")
  self.menuItems[index] = params

  log(VERBOSE, "Menu:insertMenuItem: setting parent menu of item")
  self.menuItems[index].menuPointer = self.menu

  self.menuItemsIndex = self.menuItemsIndex + 1
end

---Note: UI functions can perhaps never add Menu Items to their own array
---due to reallocation?
function Menu:addMenuItem(params)
  if self.menuItemsIndex >= self.menuItemsCount then
    self:reallocateMenuItems()
  end

  local menuItem = self.menuItems[self.menuItemsIndex]
  menuItem.menuPointer = self.menu

  if params.menuItemType == nil and menuItem.menuItemType == 0x66 then
    error(string.format("Menu:addMenuItem: menu item type not specified, menu item will not work %X"))
  end

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