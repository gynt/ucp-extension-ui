--manager/init.lua
local ffi = modules.cffi:cffi()
modules.cffi:importHeaderFile("ucp/modules/ui/ui/headers/latest/ui.h")

local CODE_PushMenuViewIDMenuMapping, pMenuViewIDMenuMapping = utils.AOBExtract("68 I(? ? ? ?) B9 ? ? ? ? 89 ? ? ? ? ? E8 ? ? ? ? 68 04 02 00 00")
local MenuViewIDMenuMapping = ffi.cast("MenuIDMenuElementAddressPair*", pMenuViewIDMenuMapping)

local _, pModalMenuStackTop = utils.AOBExtract("8B ? I(? ? ? ?) 89 50 24")

local oldOne = nil

local function logMenuPair(mp)
  local pMenuItemArray = 0
  if mp.menuID ~= -1 and mp.menuAddress ~= 0 and mp.menuAddress ~= -1 then
    pMenuItemArray = ffi.tonumber(ffi.cast("unsigned long *", mp.menuAddress)[0])
  end
  log(VERBOSE, string.format("%d \t 0x%X \t 0x%X", mp.menuID, ffi.tonumber(ffi.cast("long", mp.menuAddress)), pMenuItemArray))
end

local function reallocateMenuPairArray(old, oldSize, newSize)
  oldOne = old -- store it here so it doesn't get garbage collected just yet
  local ct = string.format("MenuIDMenuElementAddressPair[%s]", newSize)
  log(VERBOSE, ct)
  local new = ffi.new(ct, {})
  ffi.copy(new, old, ffi.sizeof("MenuIDMenuElementAddressPair") * oldSize)
  for i=oldSize,newSize do
    new[i].menuID = -1 -- mark as end element for all new empty entries
    new[i].menuAddress = ffi.nullptr
  end
  local addr = ffi.tonumber(ffi.cast("unsigned long", new))
  core.writeCodeInteger(CODE_PushMenuViewIDMenuMapping + 1, addr)

  --debug INFO
  log(VERBOSE, "MENUS")
  for i=0,newSize do
    logMenuPair(new[i])
  end

  return new
end

local ManagerSingletonState = {}

---@class Manager
local Manager = {}
function Manager.initialize(options)
  local options = options or {}
  options.menuEntryCount = options.menuEntryCount or 200

  local self = ManagerSingletonState
  if self.initialized then return end

  -- So why does this break, why is using rellocate with 50 instead of 51 breaking?
  -- self.menuIDAddressPairList = MenuViewIDMenuMapping
  -- self.maxMenus = Manager.countMenuEntries()
  -- self.currentFreeMenuIndex = self.maxMenus
  -- local factor = tonumber(string.format("%i", options.menuEntryCount / self.maxMenus))
  -- self.expansionAllowed = true
  -- Manager.expandIfNecessary(factor)
  -- self.expansionAllowed = false

  self.menuIDAddressPairList = reallocateMenuPairArray(MenuViewIDMenuMapping, 50 + 1, options.menuEntryCount + 1)
  self.maxMenus = options.menuEntryCount
  self.currentFreeMenuIndex = 50 -- override the first "-1" we find

  self.modalMenuStackTop = ffi.cast("struct MenuModal **", pModalMenuStackTop)

  self.initialized = true


  
end

function Manager.countMenuEntries()
  local unavailable = Manager.getUnavailableMenuIDs()
  local total = 0
  for k, v in pairs(unavailable) do
    if v == true then 
      total = total + 1
    end
  end

  return total
end

function Manager.expandIfNecessary(factor)
  local factor = factor or 2
  if factor <= 1 then error("factor cannot be <= 1") end

  local self = ManagerSingletonState

  if self.currentFreeMenuIndex >= self.maxMenus then -- We use >= as we allocate +1 (to contain the stop value "-1")
    if not self.expansionAllowed then
      error("expansion of menu array after initial boot is currently not yet supported")
    end

    local newSize = self.maxMenus * factor
    log(INFO, string.format("expanding menu id array from old size (%s) to new size (%s)", self.maxMenus, newSize))
    
    self.menuIDAddressPairList = reallocateMenuPairArray(self.menuIDAddressPairList, self.maxMenus + 1, newSize + 1)
    self.currentFreeMenuIndex = self.maxMenus
    self.maxMenus = newSize
  end
end

function Manager.getUnavailableMenuIDs()
  local self = ManagerSingletonState

  local unavailable = {}
  for i=0, self.maxMenus do --todo: technically a while true 
    local id = self.menuIDAddressPairList[i].menuID
    if id ~= -1 then
      unavailable[id] = true
    else
      break
    end
  end

  return unavailable
end

local function chooseAvailable(unavailable, preferredID)

  local preferredID = preferredID or 1
  local chosen = -1
  if preferredID <= 0 then
    error(string.format("illegal preferred ID: '%s'", preferredID))
  end
  if unavailable[preferredID] == true then
    for i=preferredID+1, preferredID+1000 do -- start trying from preferredID onwards
      if unavailable[i] ~= true then
        chosen = i
        break
      end
    end
  else
    chosen = preferredID
  end

  if chosen == -1 then error("invalid menu") end

  return chosen
  
end

function Manager.getAvailableMenuID(preferredID)
  local unavailable = Manager.getUnavailableMenuIDs()
  return chooseAvailable(unavailable, preferredID)
end

function Manager.registerMenu(menuAddress, preferredID)
  local self = ManagerSingletonState
  log(INFO, string.format("Registering menu (0x%X ID %s) at index: %s", menuAddress, preferredID, self.currentFreeMenuIndex))
  Manager.expandIfNecessary()

  local chosen = Manager.getAvailableMenuID(preferredID)

  if self.currentFreeMenuIndex > 0 then
    if self.menuIDAddressPairList[self.currentFreeMenuIndex - 1].menuID == -1 then
      error("non contiguous error")
    end
  end
  

  if self.menuIDAddressPairList[self.currentFreeMenuIndex].menuID ~= -1 then
    error("menu ID slot already taken")
  end

  if chosen ~= preferredID then
    log(WARNING, string.format("registerMenu: preferred ID '%s' is already taken", preferredID))
  end
  self.menuIDAddressPairList[self.currentFreeMenuIndex].menuID = chosen
  self.menuIDAddressPairList[self.currentFreeMenuIndex].menuAddress = ffi.cast("struct Menu *", menuAddress)

  self.currentFreeMenuIndex = self.currentFreeMenuIndex + 1

  log(VERBOSE, string.format("%d \t 0x%X", chosen, menuAddress))

  return chosen
end

function Manager.lookupMenu(menuID)
  local self = ManagerSingletonState
  for i=0,self.maxMenus do
    local m = self.menuIDAddressPairList[i]
    local id = m.menuID
    if id == -1 then
      return nil
    end
    if id == menuID then
      return m.menuAddress
    end
  end
end



function Manager.getUnavailableModalMenuIDs()
  local self = ManagerSingletonState

  local unavailable = {}

  local current = self.modalMenuStackTop[0]
  local currentAddr = ffi.tonumber(ffi.cast("unsigned long", current))
  
  while currentAddr > 0 and currentAddr < 4294967295 do
    local id = current.menuModalID
    unavailable[id] = true
    
    current = current.pointerToNextModalMenu
    currentAddr = ffi.tonumber(ffi.cast("unsigned long", current))
  end

  return unavailable
end

function Manager.lookupModalMenu(menuID)
  local self = ManagerSingletonState
  local current = self.modalMenuStackTop[0]
  local currentAddr = ffi.tonumber(ffi.cast("unsigned long", current))

  while currentAddr > 0 and currentAddr < 4294967295 do
    local id = current.menuModalID
    
    if id == menuID then
      return current
    end
    
    current = current.pointerToNextModalMenu
    currentAddr = ffi.tonumber(ffi.cast("unsigned long", current))
  end

  return nil
end

function Manager.getAvailableModalMenuID(preferredID)
  local unavailable = Manager.getUnavailableModalMenuIDs()
  return chooseAvailable(unavailable, preferredID)
end

function Manager.printMenus()
  for i=0,ManagerSingletonState.maxMenus do
    logMenuPair(ManagerSingletonState.menuIDAddressPairList[i])
  end
end

function Manager.getState()
  return ManagerSingletonState
end

return Manager