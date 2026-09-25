local locale_util = require 'locale_util'

-- The text a client of `lcid` reads; nil lcid means the neutral file.
-- nil result: the key stays out of that file (client default applies).
local function pick(value, lcid)
    if type(value) ~= 'table' then
        return value
    end
    if lcid then
        for _, loc in ipairs(locale_util.get_locales(value)) do
            if loc.lcid == lcid then
                return loc.text
            end
        end
    end
    return value[1]
end

local function add_obj(name, obj, lines, lcid)
    local keys = {}
    for key in pairs(obj) do
        keys[#keys+1] = key
    end
    table.sort(keys)

    lines[#lines+1] = '[' .. name .. ']'
    for _, key in ipairs(keys) do
        local value = pick(obj[key], lcid)
        if value ~= nil then
            value = tostring(value):gsub('\r\n', '|n'):gsub('[\r\n]', '|n')
            lines[#lines+1] = key .. '=' .. value
        end
    end
end

local function convert(skin, lcid)
    local lines = {}
    local names = {}
    for name in pairs(skin) do
        names[#names+1] = name
    end
    table.sort(names)

    for _, name in ipairs(names) do
        add_obj(name, skin[name], lines, lcid)
    end

    return table.concat(lines, '\r\n')
end

return function(w2l, skin, lcid)
    return convert(skin, lcid)
end
