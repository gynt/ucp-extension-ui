local pSwitchToMenuView = core.exposeCode(core.AOBScan("55 8B 6C 24 08 83 FD 17"), 3, 1)
local _, pThis = utils.AOBExtract("A3 I( ? ? ? ? ) 89 5C 24 1C")

---@type luajit
local luajit = modules.luajit

---@type LuaJITState
local state

local manager = require("manager")
manager.initialize()

---@class Module_UI
local ui = {}

local function initialize(options)
  local options = options or {
    headers = 'latest',
  }
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
    globals = {},
    interface = {
      env = _ENV,
      extra = {
        AOBScan = function(target)
          return core.AOBScan(target)
        end,
        manager = manager,
      }
    }
  })

  state:importHeaderFile(string.format("ucp/modules/ui/ui/headers/%s/ui.h", options.headers))
  state:executeString([[ui = require("ui")]])

  return state
end

function ui:enable()

  state = initialize()


end

function ui:disable()

end


function ui:registerMenu(menuAddress, preferredID)
  return manager.registerMenu(menuAddress, preferredID)
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

function ui:testInterface()
  return {
    game = require("ui.game"),
    api = require("ui.menu"),
    manager = manager,
  }
end

--- Bad idea for now:
-- ---Creates a basic UI state from scratch
-- ---Only useful if you don't want to use the global UI state of this module
-- ---@return LuaJITState
-- function ui:createState()
--   return initialize()
-- end


return ui, {
  proxy = {
    ignored = {
      "getState",
      "createState",
    }
  }
}