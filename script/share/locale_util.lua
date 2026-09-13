local ok, mod = pcall(require, 'core.locale_util')
if ok then
    return mod
end
return require 'locale_util'

