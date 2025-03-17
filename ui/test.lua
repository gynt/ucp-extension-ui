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

events.receive('ping', function(key, value)
  events.send('pong', "well received!")
end)