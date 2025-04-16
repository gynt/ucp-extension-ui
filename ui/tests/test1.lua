local function prepare()
  log( VERBOSE, "prepare(): ")
end

-- PencilRenderCore* this
local drawColorBox = ffi.cast("void (__thiscall *)(void *this,int left,int top,int right,int bottom, short color)", 0x00470e90)
local drawColorBox_this = ffi.cast("void *", 0x0191d720)
local pCOLOR_BLACK = ffi.cast("short *", 0x00df33d0)
local function initial()
  log(VERBOSE, "initial(): ")
  drawColorBox(drawColorBox_this, 0, 0, 1280, 720, pCOLOR_BLACK[0])
end

local function frame()
  
end

menu = Menu:createMenu({
  menuID = 99,
  menuItemsCount = 100,
  pPrepare = ffi.cast("void (*)(void)", addr_0x00424c40),
  pInitial = ffi.cast("void (*)(void)", addr_0x00424cd0),
  pFrame = ffi.cast("void (*)(void)", addr_0x00424da0),
})

mainMenuMenuItems = ffi.cast("MenuItem *", 0x005e81c8)
ffi.copy(menu.menuItems, mainMenuMenuItems, 99 * ffi.sizeof("MenuItem"))

remote.events.receive('ping', function(key, value)
  remote.events.send('pong', "well received!")
end)

core = remote.interface.core

remote.events.receive('aob', function(key, value)
  log(INFO, remote.invoke("AOBScan", "00 11 22 33"))
end)


remote.events.receive('aob', function(key, value)
  log(INFO, core.AOBScan("00 11 22 33"))
end)


F = function(a) return {a = a} end
G = function(a) return {a = a, b = 100}, 200, "" end