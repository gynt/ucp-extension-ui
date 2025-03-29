DAT_MenuViewIDMenuMapping = ffi.cast("MenuIDMenuElementAddressPair*", DAT_MenuViewIDMenuMapping)

newMenusList = ffi.new("MenuIDMenuElementAddressPair[100]", {[0] = {}})

ffi.copy(newMenusList, DAT_MenuViewIDMenuMapping, ffi.sizeof("MenuIDMenuElementAddressPair") * 51)

for i=51,99 do
  newMenusList[i].menuID = -1 -- mark as end element for all empty entries
end

writeCodeInteger(CODE_PushMenuViewIDMenuMapping + 1, tonumber(ffi.cast("unsigned int", newMenusList)))
