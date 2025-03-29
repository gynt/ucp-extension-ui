
---@type fun(menu: struct_Menu, menuItems: table): struct_Menu
_Menu = ffi.cast([[
  Menu *
  (__thiscall *)
  (
    Menu *this, 
    MenuItem *menuItemArrayAddress
  )
]], CODE_MenuConstructor)

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
]], CODE_MenuViewConstructor)

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
    MenuModalRenderFunction *renderFunctionPtr,
    Menu *menuPtr
  )
]], CODE_MenuModal)