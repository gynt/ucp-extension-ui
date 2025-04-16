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

local core = remote.interface.core
local addr_0x00424c40 = core.AOBScan("56 33 F6 68 ? ? ? ? B9 ? ? ? ? 89 ? ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? E8 ? ? ? ? 56 ")
local addr_0x00424cd0 = core.AOBScan("0F ? ? ? ? ? ? 8B ? ? ? ? ? 8B ? ? ? ? ? 56 50 51 52 6A 00 6A 00 B9 ? ? ? ? E8 ? ? ? ? E8 ? ? ? ? 8B ? ? ? ? ? A1 ? ? ? ? 8B CE C1 E1 04 2B ? ? ? ? ? 99 2B C2 D1 F8 50 A1 ? ? ? ? 2B ? ? ? ? ? B9 ? ? ? ? 99 2B C2 D1 F8 50 56 E8 ? ? ? ? A1 ? ? ? ? 8B ? ? ? ? ? 8B ? ? ? ? ? 89 4A 04 89 42 08 6A 00 ")
local addr_0x00424da0 = core.AOBScan("83 EC 68 A1 ? ? ? ? 33 C4 89 44 24 64 83 ? ? ? ? ? ? 0F ? ? ? ? ? 83 ? ? ? ? ? ?")

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

remote.events.receive('aob', function(key, value)
  log(INFO, remote.invoke("AOBScan", "00 11 22 33"))
end)


remote.events.receive('aob', function(key, value)
  log(INFO, core.AOBScan("00 11 22 33"))
end)


F = function(a) return {a = a} end
G = function(a) return {a = a, b = 100}, 200, "" end