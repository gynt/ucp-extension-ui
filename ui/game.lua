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

local pRenderGMWithBlending = core.AOBScan("8B 54 24 08 56 8B 74 24 08 8B ? ? ? ? ? ? 8D 44 10 FF ")
game.Rendering.renderGMWithBlending = ffi.cast([[

  void (__thiscall *)
  (
    void *this, // textureRenderCore
    int gmID,
    int imageID,
    int drawX,
    int drawY,
    int blendStrength
  )

]], pRenderGMWithBlending)

local _, pTextureRenderCore = utils.AOBExtract("39 ? I( ? ? ? ? ) 74 05 83 C8 FF")
game.Rendering.textureRenderCore = ffi.cast("void *", pTextureRenderCore)

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
game.Rendering.textManager = ffi.cast("void *", pTextManager)

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

game.Rendering.renderTextToScreenConst = ffi.cast([[
  void (__thiscall *)
  (
    void * this, //Text Manager
    char const *textAddress, 
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
---@class ButtonRenderState
---@field x number
---@field y number
---@field width number
---@field height number
---@field interacting number
---@field gmDataIndex number
---@field gmPictureIndex number
---@field blendStrength number
---@type ButtonRenderState
game.Rendering.ButtonState = ffi.cast([[
  ButtonRenderState *
]], pButtonState)

game.Rendering.renderButtonBackground = ffi.cast([[
  void (__thiscall *)
  (
    void * this, // Alpha and button surface
    int blendStrength,
    int renderTarget
  )
    
]], core.AOBScan("8B 44 24 04 83 EC 08"))

local pRenderButtonGM = core.AOBScan("56 33 F6 39 ? ? ? ? ? 57 74 05")
game.Rendering.renderButtonGM = ffi.cast("void (*)(void)", pRenderButtonGM)

local _, pAlphaAndButtonSurface = utils.AOBExtract("8B ? I( ? ? ? ? ) 89 ? ? ? ? ? 8B ? ? ? ? ? D1 E2")
game.Rendering.alphaAndButtonSurface = ffi.cast("void *", pAlphaAndButtonSurface)

game.Rendering.drawColorBox = ffi.cast([[
  void (__thiscall *)
  (
    void * this, // pencilrendercore
    int left,
    int top,
    int right,
    int bottom,
    unsigned short color
  )
]], core.AOBScan("56 8B F1 E8 ? ? ? ? 8B 44 24 18 8B 4C 24 14 8B 54 24 10 50 8B 44 24 10 51 8B 4C 24 10 52 50 51 8B CE E8 ? ? ? ? 85 C0 74 1B "))

game.Rendering.drawBlendedBlackBox = ffi.cast([[
  void (__thiscall *)
  (
    void * this,
    int left,
    int top,
    int right,
    int bottom,
    int blendStrength
  )
]], core.AOBScan("56 8B F1 E8 ? ? ? ? 8B 44 24 14 8B 4C 24 10 8B 54 24 0C 6A 00 50 8B 44 24 10 51 52 50 8B CE E8 ? ? ? ? 85 C0 74 1F"))

game.Rendering.drawBorderBox = ffi.cast([[
  void (__thiscall *)
  (
    void * this, //pencilRenderCore
    int left,
    int top,
    int right,
    int bottom,
    unsigned short color
  )
]], core.AOBScan("56 8B F1 E8 ? ? ? ? 8B 44 24 18 8B 4C 24 14 8B 54 24 10 50 8B 44 24 10 51 8B 4C 24 10 52 50 51 8B CE E8 ? ? ? ? 85 C0 74 36"))

local _, pPencilRenderCore = utils.AOBExtract("B9 I( ? ? ? ? ) E8 ? ? ? ? 39 7E D8")
game.Rendering.pencilRenderCore = ffi.cast("void *", pPencilRenderCore)

game.Rendering.renderNumberToScreen2 = ffi.cast([[
  void (__thiscall *)
  (
    void * this, // text manager
    int number,
    int xParam,
    int yParam,
    int alignment,
    unsigned int color,
    int fontSize,
    bool keepOffsetX,
    int blendStrength
  )

]], core.AOBScan("8B 44 24 04 56 50 8B F1 E8 ? ? ? ? 8B 4C 24 24"))


local pGeneralButtonRender = core.AOBScan("A1 ? ? ? ? 8B ? ? ? ? ? 8D 0C C5 00 00 00 00 2B C8 A1 ? ? ? ? 50 A1 ? ? ? ? 52 8D ? ? ? ? ? ? 50 C7 ? ? ? ? ? ? ? ? ? E8 ? ? ? ? 8B 09 50 51 B9 ? ? ? ? E8 ? ? ? ? A1 ? ? ? ? 8D 14 C5 00 00 00 00 2B D0 8B ? ? ? ? ? ? A3 ? ? ? ? C7 ? ? ? ? ? ? ? ? ? C3", core.AOBScan("83 ? ? ? ? ? ? 56 8B 74 24 08 75 20"))
game.Rendering.generalButtonRender = ffi.cast([[
  void (__cdecl *)
  (
    int param_1,
    ...
  )
]], pGeneralButtonRender)

local _, pColorGreyishYellow = utils.AOBExtract("66 ? I( ? ? ? ? ) E8 ? ? ? ? 6A 58")
local _, pColorDarkLime = utils.AOBExtract("66 ? I( ? ? ? ? ) E8 ? ? ? ? 6A 00 6A 00 68 8C 00 00 00")

game.Rendering.Colors = {
  pGreyishYellow = ffi.cast("unsigned short *", pColorGreyishYellow),
  pColorDarkLime = ffi.cast("unsigned short *", pColorDarkLime),
}

if game.Input == nil then game.Input = {} end

game.Input.isMouseInsideBox = ffi.cast([[
  int (__thiscall *)
  (
    void * this,
    int x,
    int y,
    int width,
    int height
  )
]], core.AOBScan("8B 41 10 8B 54 24 04"))

local _, pMouseState = utils.AOBExtract("B9 I( ? ? ? ? ) 89 ? ? ? ? ? 89 ? ? ? ? ? 89 ? ? ? ? ? 89 ? ? ? ? ? E8 ? ? ? ? 89 ? ? ? ? ?")
game.Input.mouseState = ffi.cast("void *", pMouseState)

local _, mmc1 = utils.AOBExtract("B9 I( ? ? ? ? ) E8 ? ? ? ? 5E 5B E9 ? ? ? ?")
game.UI.modalMenu = ffi.cast("struct MenuModal *", mmc1)

if not remote then
  return game
end