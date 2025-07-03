-- ui/game.lua
local core = core
if remote ~= nil then
  core = remote.interface.core
end

local utils = utils
if remote ~= nil then
  utils = remote.interface.utils
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
if remote ~= nil then
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

if game.Rendering == nil then
  game.Rendering = {}
end

local pRenderGM = core.AOBScan("8B 54 24 08 56 8B 74 24 08 8B ? ? ? ? ? ? 69 F6 58 14 00 00")
game.Rendering.renderGM = ffi.cast([[
  void (__thiscall *)
  (
    void *this, // textureRenderCore
    int gmID,
    int imageID,
    int drawX,
    int drawY
  )
]], pRenderGM)

local _, pTextureRenderCore = utils.AOBExtract("39 ? I( ? ? ? ? ) 74 05 83 C8 FF")
game.Rendering.pTextureRenderCore = pTextureRenderCore

local pRenderNumber2 = core.AOBScan("8B 44 24 04 53 55 56 57 50")
game.Rendering.renderNumber2 = ffi.cast([[
  void (__thiscall *)
  (
    void *this, // text manager
    int integer,
    int xPosition,
    int yPosition,
    int textAlignment,
    unsigned int color,
    unsigned int param_6,
    int fontSize,
    bool param_8,
    int param_9
  )
]], pRenderNumber2)

local _, pTextManager = utils.AOBExtract("89 ? I( ? ? ? ? ) 7E 05")
game.Rendering.pTextManager = pTextManager

game.Rendering.renderTextToScreen = ffi.cast([[
  void (__thiscall *)
  (
    void * this, //Text Manager
    char *textAddress, 
    int xParam,
    int yParam,
    int alignment,
    unsigned int color,
    int fontSize,
    bool keepOffsetX,
    int blendStrength
  )
]], core.AOBScan("83 7C 24 1C 00 53 56 8B F1 75 06 C7 06 00 00 00 00 8B 5C 24 0C 85 DB 74 7C"))

game.Rendering.getTextStringInGroupAtOffset = ffi.cast([[
  char * (__thiscall *)
  (
    void * this, // Text manager
    int groupIndex,
    int itemInGroup
  )
]], core.AOBScan("8B 44 24 04 8D 50 FB"))

local _, pButtonState = utils.AOBExtract("8B ? I( ? ? ? ? ) 8D 44 38 65")
game.Rendering.ButtonState = ffi.cast([[
  ButtonRenderState *
]], pButtonState)

if not remote then
  return game
end