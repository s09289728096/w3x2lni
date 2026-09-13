-- Run the real backend with readable output (the native CLI requires a console).
-- From script/: ../bin/w3x2lni-lua.exe ../test/locale_cli.lua unpack INPUT OUTPUT
package.path = './?.lua;./?/init.lua;' .. package.path
package.cpath = '../bin/?.dll;' .. package.cpath
require 'utility'
local messager = {}
for _, key in ipairs {'text', 'title', 'progress', 'wait'} do
    messager[key] = function() end
end
messager.raw = print
messager.report = function(kind, level, content, tip)
    print(kind, level, content, tip)
end
messager.exit = function(kind, content)
    print(kind, content)
    assert(kind ~= 'error', content)
end
package.loaded['share.messager'] = messager
require 'backend'
