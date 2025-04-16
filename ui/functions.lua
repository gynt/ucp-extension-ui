-- ui/functions.lua
local core = remote.interface.core

local pMenuViewConstructor = core.AOBScan("8B 54 24 08 8B C1 8B 4C 24 04 89 48 04")
local pMenuConstructor = core.AOBScan("51 53 8B D9")
local pMenuModalConstructor = core.AOBScan("8B 54 24 08 8B C1 8B 4C 24 04 89 08")

---@type fun(menu: struct_Menu, menuItems: table): struct_Menu
_Menu = ffi.cast([[
  Menu *
  (__thiscall *)
  (
    Menu *this, 
    MenuItem *menuItemArrayAddress
  )
]], pMenuConstructor)

---@type fun(menuView: number, menuID: number, prepareMenuView: fun(), doInitial: fun(), doEveryFrame: fun())
_MenuView = ffi.cast([[
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
_MenuModal = ffi.cast([[
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