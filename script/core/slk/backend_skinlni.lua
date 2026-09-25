-- Writes the game interface as table\skin.ini: one [section] per skin
-- section, each key a plain string, or a locale table once translated
-- (same syntax as table\w3i.ini).
local locale_util = require 'locale_util'

local format_single_string = locale_util.format_single_string

local function sorted_keys(tbl)
    local keys = {}
    for key in pairs(tbl) do
        keys[#keys+1] = key
    end
    table.sort(keys)
    return keys
end

local function format_value(value)
    if type(value) ~= 'table' then
        return format_single_string(value)
    end
    local lines = {'{'}
    -- No default means only the tagged locales carry this key.
    if value[1] ~= nil then
        lines[#lines+1] = ('    %s,'):format(format_single_string(value[1]))
    end
    for _, loc in ipairs(locale_util.get_locales(value)) do
        lines[#lines+1] = ('    %s = %s,'):format(loc.tag, format_single_string(loc.text))
    end
    lines[#lines+1] = '}'
    return table.concat(lines, '\r\n')
end

return function (w2l, skin)
    local lines = {}
    for i, name in ipairs(sorted_keys(skin)) do
        if i > 1 then
            lines[#lines+1] = ''
        end
        lines[#lines+1] = ('[%s]'):format(name)
        local section = skin[name]
        for _, key in ipairs(sorted_keys(section)) do
            lines[#lines+1] = ('%s = %s'):format(key, format_value(section[key]))
        end
    end
    return table.concat(lines, '\r\n')
end
