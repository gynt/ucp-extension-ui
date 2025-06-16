-- ui/game.lua
local core = core
if remote then
  core = remote.interface.core
end

local ffi = ffi
if not remote then
  ffi = modules.cffi:cffi()
end


local pMenuViewConstructor = core.AOBScan("8B 54 24 08 8B C1 8B 4C 24 04 89 48 04")
local pMenuConstructor = core.AOBScan("51 53 8B D9")
local pMenuModalConstructor = core.AOBScan("8B 54 24 08 8B C1 8B 4C 24 04 89 08")

local game = game or {}
game.UI = game.UI or {}
if remote then
  _G.game = game
end


---@type fun(menu: struct_Menu, menuItems: table): struct_Menu
game.UI.Menu = ffi.cast([[
  Menu *
  (__thiscall *)
  (
    Menu *this, 
    MenuItem *menuItemArrayAddress
  )
]], pMenuConstructor)

---@type fun(menuView: number, menuID: number, prepareMenuView: fun(), doInitial: fun(), doEveryFrame: fun())
game.UI.MenuView = ffi.cast([[
  struct MenuView * 
  (__thiscall *)
  (
    struct MenuView * this, 
    MenuViewType menuID,
    pCdeclVoidFunc prepareMenuView, 
    pCdeclVoidFunc doInitial,
    pCdeclVoidFunc doEveryFrame
  )
]], pMenuViewConstructor)

---@type fun(menuModal: number, menuModalId: number, x: number, y: number, width: number, height: number, borderStyle: number, backgroundColourIndex: number, renderFunctionPointer: fun(), menuPtr: number)
game.UI.MenuModal = ffi.cast([[
  struct MenuModal * (__thiscall *)
  (
    struct MenuModal *this,
    MenuModalType menuModalId,
    int xPos,
    int yPos,
    int width,
    int height,
    int borderStyle,
    int backgroundColourIndex,
    void (*menuModalRenderFunction)(int, int, int, int),
    Menu *menuPtr
  )
]], pMenuModalConstructor)

if not remote then
  return game
end