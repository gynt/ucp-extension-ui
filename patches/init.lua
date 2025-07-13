


local _, pButtonState = utils.AOBExtract("8B ? I( ? ? ? ? ) 8D 44 38 65")

-- ---@type CFFIInterface
-- local ffi = modules.cffi:cffi()
-- local buttonState = ffi.cast("ButtonRenderState *", pButtonState)
--[[
typedef struct ButtonRenderState {
  int x;
  int y;
  int width;
  int height;
  int interacting;
  int gmDataIndex;
  int gmPictureIndex;
  int blendStrength;
  int unused;
  int unknownZero;
} ButtonRenderState;
--]]

--- This patch sets button x y width height and other menu item properties during action callbacks
--- Original code only does this for render callbacks
local function setButtonPropertiesPatch ()

  -- mimicked based on: 0x 004f4a26
  -- ESI should contain pointer to MenuItem (this usually)
  local l = core.AssemblyLambda([[
    PUSH       EAX
    PUSH       ECX
    PUSH       EDX

    MOV        EAX,dword [ESI + 0x4c] ; menuPointer
    MOV        ECX,dword [EAX + 0x4]
    SUB        ECX,dword [EAX + 0x14]
    ADD        ECX,dword [ESI + 0x4]
    MOV        dword [px],ECX
    MOV        EDX,dword [ESI + 0x4c]
    MOV        EAX,dword [EDX + 0x8]
    ADD        EAX,dword [ESI + 0x8]
    MOV        dword [py],EAX
    MOV        ECX,dword [ESI + 0xc]
    MOV        dword [pwidth],ECX
    MOV        EDX,dword [ESI + 0x10]
    MOV        dword [pheight],EDX
    MOV        EAX,dword [ESI + 0x20]
    AND        EAX, 0x7fffff
    MOV        dword [pgmDataIndex],EAX
    MOVSX      EAX,word [ESI + 0x34]
    MOVSX      ECX,word [ESI + 0x32]
    OR         EAX,ECX
    MOV        dword [pinteracting],EAX
    MOVSX      EDX,word [ESI + 0x38]
    MOV        dword [pUnknownZero],EDX

    POP        EDX
    POP        ECX
    POP        EAX
  ]], {
    px = pButtonState + 0,
    py = pButtonState + 4,
    pwidth = pButtonState + 8,
    pheight = pButtonState + 12,
    pinteracting = pButtonState + 16,
    pgmDataIndex = pButtonState + 20,
    pgmPictureIndex = pButtonState + 24,
    -- pBlendStrength = pButtonState + 28,
    pUnknownZero = pButtonState + 36,
  })

  core.insertCode(core.AOBScan("57 8B 3E 81 ? ? ? ? ?"), 9, {l}, nil, 'after')

end

return {
  setButtonPropertiesPatch = setButtonPropertiesPatch,
}