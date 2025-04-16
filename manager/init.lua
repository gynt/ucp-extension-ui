local ffi = modules.cffi:cffi()
modules.cffi:importHeaderFile("ucp/modules/ui/ui/headers/latest/ui.h")

log(VERBOSE, string.format("ffi: %s", tostring(ffi)))

for k, v in pairs(ffi) do
  print(k, v)
end

local CODE_PushMenuViewIDMenuMapping, pMenuViewIDMenuMapping = utils.AOBExtract("68 I(? ? ? ?) B9 ? ? ? ? 89 ? ? ? ? ? E8 ? ? ? ? 68 04 02 00 00")
local MenuViewIDMenuMapping = ffi.cast("MenuIDMenuElementAddressPair*", pMenuViewIDMenuMapping)


local oldOne = nil

local function reallocate(old, oldSize, newSize)
  oldOne = old -- store it here so it doesn't get garbage collected just yet
  local ct = string.format("MenuIDMenuElementAddressPair[%s]", newSize)
  log(VERBOSE, ct)
  local new = ffi.new(ct, {})
  ffi.copy(new, old, ffi.sizeof("MenuIDMenuElementAddressPair") * oldSize)
  for i=oldSize,newSize do
    new[i].menuID = -1 -- mark as end element for all new empty entries
    new[i].menuAddress = ffi.nullptr
  end
  local addr = ffi.tonumber(ffi.cast("long", new))
  core.writeCodeInteger(CODE_PushMenuViewIDMenuMapping + 1, addr)

  return new
end

local Manager = {}
function Manager:initialize(options)
  if self.initialized then return end
  local options = options or {
    menuEntryCount = 200,
  }

  self.menuIDAddressPairList = reallocate(MenuViewIDMenuMapping, 51, options.menuEntryCount)
  self.maxMenus = options.menuEntryCount
  self.currentFreeMenuIndex = 51
  self.initialized = true
end

function Manager:expandIfNecessary()
  if self.currentFreeMenuIndex >= self.maxMenus then
    self.menuIDAddressPairList = reallocate(self.menuIDAddressPairList, self.maxMenus, self.maxMenus * 2)
    self.currentFreeMenuIndex = self.maxMenus
  end
end
function Manager:registerMenu(menuAddress, preferredID)
  self:expandIfNecessary()

  local unavailable = {}
  for i=0,(self.maxMenus - 1) do
    local id = self.menuIDAddressPairList[i].menuID
    if id ~= -1 then
      unavailable[id] = true
    end
  end

  local chosen = -1
  if preferredID < 0 then
    error(string.format("registerMenu: illegal preferred ID: '%s'", preferredID))
  end
  if unavailable[preferredID] == true then
    log(WARNING, string.format("registerMenu: preferred ID '%s' is already taken", preferredID))
    for i=1, 1000 do
      if unavailable[i] ~= true then
        chosen = i
        break
      end
    end
  else
    chosen = preferredID
  end

  self.menuIDAddressPairList[self.currentFreeMenuIndex].menuID = chosen
  self.menuIDAddressPairList[self.currentFreeMenuIndex].menuAddress = ffi.cast("struct Menu *", menuAddress)

  self.currentFreeMenuIndex = self.currentFreeMenuIndex + 1


  return chosen
end

return Manager