local pSwitchToMenuView = core.exposeCode(core.AOBScan("55 8B 6C 24 08 83 FD 17"), 3, 1)
local _, pThis = utils.AOBExtract("A3 I( ? ? ? ? ) 89 5C 24 1C")

---@type luajit
local luajit = modules.luajit

---@type LuaJITState
local state

local ui = {}

local addr_0x0057bfc3, addr_0x00613418 = utils.AOBExtract("68 I(? ? ? ?) B9 ? ? ? ? 89 ? ? ? ? ? E8 ? ? ? ? 68 04 02 00 00")
local addr_0x00424c40 = core.AOBScan("56 33 F6 68 ? ? ? ? B9 ? ? ? ? 89 ? ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? E8 ? ? ? ? 56 ")
local addr_0x00424cd0 = core.AOBScan("0F ? ? ? ? ? ? 8B ? ? ? ? ? 8B ? ? ? ? ? 56 50 51 52 6A 00 6A 00 B9 ? ? ? ? E8 ? ? ? ? E8 ? ? ? ? 8B ? ? ? ? ? A1 ? ? ? ? 8B CE C1 E1 04 2B ? ? ? ? ? 99 2B C2 D1 F8 50 A1 ? ? ? ? 2B ? ? ? ? ? B9 ? ? ? ? 99 2B C2 D1 F8 50 56 E8 ? ? ? ? A1 ? ? ? ? 8B ? ? ? ? ? 8B ? ? ? ? ? 89 4A 04 89 42 08 6A 00 ")
local addr_0x00424da0 = core.AOBScan("83 EC 68 A1 ? ? ? ? 33 C4 89 44 24 64 83 ? ? ? ? ? ? 0F ? ? ? ? ? 83 ? ? ? ? ? ?")
local pMenuViewConstructor = core.AOBScan("8B 54 24 08 8B C1 8B 4C 24 04 89 48 04")
local pMenuConstructor = core.AOBScan("51 53 8B D9")
local pMenuModal = core.AOBScan("8B 54 24 08 8B C1 8B 4C 24 04 89 08")

local function initialize()
  local state = luajit:createState({
    name = "ui",
    requireHandler = function(self, path)
      local handle, err = io.open(string.format("ucp/modules/ui/%s.lua", path))
      if not handle then
        handle, err = io.open(string.format("ucp/modules/ui/%s/init.lua", path))
      end
    
      if not handle then
        error( err)
      end
    
      local contents = handle:read("*all")
      handle:close()

      return contents
    end,
    globals = {
      DAT_MenuViewIDMenuMapping = addr_0x00613418,
      CODE_PushMenuViewIDMenuMapping = addr_0x0057bfc3,
      CODE_MenuViewConstructor = pMenuViewConstructor,
      CODE_MenuConstructor = pMenuConstructor,
      CODE_MenuModal = pMenuModal,
      addr_0x00424c40 = addr_0x00424c40,
      addr_0x00424cd0 = addr_0x00424cd0,
      addr_0x00424da0 = addr_0x00424da0,
    },
    interface = {
      env = _ENV,
      extra = {
        AOBScan = function(target)
          return core.AOBScan(target)
        end,
      }
    }
  })

  state:executeString([[ui = require("ui")]])

  return state
end

function ui:enable()

  state = initialize()


end

function ui:disable()

end


function ui:switchToMenu(menuID, delay)
  pSwitchToMenuView(pThis, menuID or 41, delay or 0)
end

local _, mmc1 = utils.AOBExtract("B9 I( ? ? ? ? ) E8 ? ? ? ? 5E 5B E9 ? ? ? ?")
local _, mmc2 = utils.AOBExtract("B9 I(? ? ? ?) E8 ? ? ? ? B9 ? ? ? ? 89 ? ? ? ? ? 89 ? ? ? ? ? 89 ? ? ? ? ?")
local _, mmc3 = utils.AOBExtract("B9 I( ? ? ? ? ) E8 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 8B ? ? ? ? ? 8B ? ? ? ? ? A1 ? ? ? ?")
local mmcNonpersistent = mmc1
local mmcPersistent = mmc2
local _activateModalDialog = core.exposeCode(core.AOBScan("53 55 33 ED 39 6C 24 10"), 3, 1)

function ui:activateModalMenu(menuID, slot, delay)
  if slot == 1 then
    _activateModalDialog(mmcNonpersistent, menuID or -1, delay or 0)
  else
    _activateModalDialog(mmcPersistent, menuID or -1, delay or 0)
  end
end

function ui:createMenuFromFile(path)
  state:executeFile(path)
end

function ui:registerEventHandler(key, func)
  state:registerEventHandler(key, func)
end

function ui:sendEvent(key, obj)
  state:sendEvent(key, obj)
end

function ui:registerRequireHandler(func)
  state:registerRequireHandler(func)
end

---@return LuaJITState
function ui:getState()
  return state
end

--- Bad idea for now:
-- ---Creates a basic UI state from scratch
-- ---Only useful if you don't want to use the global UI state of this module
-- ---@return LuaJITState
-- function ui:createState()
--   return initialize()
-- end

function ui:testMenu()
  self:createMenuFromFile("ucp/modules/ui/ui/tests/test1.lua")
  state:registerEventHandler("pong", function(key, obj)
    log(VERBOSE, "received pong!")
  end)
  state:sendEvent("ping", "hello!")
  state:sendEvent("aob", "heyho!")
end

return ui, {
  proxy = {
    ignored = {
      "getState",
      "createState",
    }
  }
}