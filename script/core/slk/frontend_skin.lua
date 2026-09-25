-- Loads the game interface (war3mapskin.txt) as {section = {key = value}},
-- where a value is a string or a locale table {default, enUS = ..., ...}.
-- An LNI project keeps it in table\skin.ini; a map keeps a neutral
-- war3mapskin.txt plus one MPQ locale variant per translated LCID, which
-- WC3 picks by the client's locale just like war3map.wts.
local locale_util = require 'locale_util'

local function load_variants(w2l, skin)
    local input = w2l.input_ar
    if not (input and input.locales) then
        return
    end
    local wts_locales = w2l.slk.wts_locales or {}
    for _, lcid in ipairs(input:locales('war3mapskin.txt')) do
        local buf = lcid ~= 0 and input:load_locale('war3mapskin.txt', lcid)
        if buf then
            local tag = locale_util.lcid_to_tag(lcid)
            local wts = wts_locales[lcid] or w2l.slk.wts
            for name, section in pairs(w2l:parse_ini(buf)) do
                skin[name] = skin[name] or {}
                for key, text in pairs(section) do
                    text = w2l:load_wts(wts, text)
                    local value = skin[name][key]
                    local default = type(value) == 'table' and value[1] or value
                    if text ~= default then
                        if type(value) ~= 'table' then
                            -- A key only the variant has keeps no default.
                            value = {value}
                            skin[name][key] = value
                        end
                        value[tag] = text
                    end
                end
            end
        end
    end
end

return function (w2l, wts)
    local buf = w2l:file_load('table', 'skin')
    if buf then
        w2l:file_remove('table', 'skin')
        -- table\skin.ini is the only source once it exists.
        w2l:file_remove('map', 'war3mapskin.txt')
        return w2l:parse_lni(buf, 'skin')
    end
    buf = w2l:file_load('map', 'war3mapskin.txt')
    if not buf then
        return nil
    end
    w2l:file_remove('map', 'war3mapskin.txt')
    local skin = w2l:parse_ini(buf)
    for _, section in pairs(skin) do
        for key, value in pairs(section) do
            section[key] = w2l:load_localized_wts(wts, value)
        end
    end
    load_variants(w2l, skin)
    return skin
end
