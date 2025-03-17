local pSwitchToMenuView = core.exposeCode(core.AOBScan("55 8B 6C 24 08 83 FD 17"), 3, 1)
local _, pThis = utils.AOBExtract("A3 I( ? ? ? ? ) 89 5C 24 1C")

local state

local ui = {}

function ui:enable()

  state = modules.luajit:create({
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
      addr_0x00613418 = 0x00613418,
      addr_0x0057bfc3 = 0x0057bfc3,
    },
  })

  state:executeFile("ucp/modules/ui/ui/main.lua")

  state:registerEventHandler("pong", function(key, obj)
    log(VERBOSE, "received pong!")
  end)
  state:sendEvent("ping", "hello!")
end

function ui:disable()

end


function ui:switchToMenu(menuID, delay)
  pSwitchToMenuView(pThis, menuID or 41, delay or 0)
end

return ui