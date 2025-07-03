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