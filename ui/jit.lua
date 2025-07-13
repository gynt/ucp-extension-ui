---@diagnostic disable-next-line: undefined-global
local jit = jit

if jit == nil then
  jit = {
    on = function(...)
      log(WARNING, string.format("jit 'on' ignored"))
    end,
    off = function(...)
      log(WARNING, string.format("jit 'off' ignored"))
    end,
  }
end

if registerObject == nil then
  function registerObject(obj)
    
    if _G._LUAJIT_REGISTRY == nil then
      _G._LUAJIT_REGISTRY = {}
    end
    _G._LUAJIT_REGISTRY[obj] = true

    return obj
  end
end