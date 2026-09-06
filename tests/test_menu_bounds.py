from pathlib import Path
import unittest
from lupa.lua54 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]


class MenuBoundsTests(unittest.TestCase):
    def test_initialize_and_fill_capacity_keep_the_last_sentinel_in_bounds(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute('''
arrays={}; allocations={}; copies={}
function array(n)
 local entries={}; for i=0,n-1 do entries[i]={menuID=-1,menuAddress=0} end
 local a=setmetatable({}, {__index=function(_,i)
  assert(type(i)=='number' and i>=0 and i<n, 'out-of-bounds menu entry '..tostring(i))
  return entries[i]
 end})
 arrays[a]=n; return a
end
original=array(51)
for i=0,49 do original[i].menuID=i+1; original[i].menuAddress=1000+i end
ffi={nullptr=0,tonumber=function(v) return v end, sizeof=function() return 8 end}
ffi.new=function(ct)
 local count=assert(tonumber(ct:match('%[(%d+)%]')))
 local a=array(count); allocations[#allocations+1]=a; return a
end
ffi.copy=function(dst,src,size)
 assert(size%8==0)
 for i=0,size/8-1 do dst[i].menuID=src[i].menuID; dst[i].menuAddress=src[i].menuAddress end
 copies[#copies+1]=size
end
ffi.cast=function(ct,value)
 if ct=='MenuIDMenuElementAddressPair*' then return original end
 if ct=='unsigned long' and type(value)=='table' then return 5000 end
 if ct=='unsigned long *' then return {[0]=1234} end
 if ct=='struct MenuModal **' then return {[0]=0} end
 return value
end
modules={cffi={cffi=function() return ffi end,importHeaderFile=function() end}}
utils={AOBExtract=function() return 100,200 end}
core={writeCodeInteger=function(a,v) assert(a==101 and v==5000) end}
log=function() end
''')
        manager = lua.execute((ROOT / 'manager/init.lua').read_text(encoding='utf-8'))
        lua.globals().manager = manager
        lua.execute('''
manager.initialize()
local s=manager.getState(); local a=s.menuIDAddressPairList
assert(arrays[a]==201 and copies[1]==51*8)
for i=0,49 do assert(a[i].menuID==i+1 and a[i].menuAddress==1000+i) end
for i=50,200 do assert(a[i].menuID==-1 and a[i].menuAddress==0) end
for id=51,200 do assert(manager.registerMenu(1000+id,id)==id) end
assert(a[200].menuID==-1 and s.currentFreeMenuIndex==200)
assert(manager.lookupMenu(200)==1200)
assert(not pcall(manager.registerMenu,9999,201))
assert(a[200].menuID==-1 and a[199].menuID==200)
manager.printMenus()
''')


if __name__ == '__main__':
    unittest.main()
