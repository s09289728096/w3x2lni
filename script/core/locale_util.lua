local m = {}

-- Standard Warcraft III supported Windows LCIDs and language tags
local lcid_to_tag = {
    [0x0000] = 'default',
    [0x0404] = 'zhTW',
    [0x0804] = 'zhCN',
    [0x0409] = 'enUS',
    [0x0412] = 'koKR',
    [0x0411] = 'jaJP',
    [0x0419] = 'ruRU',
    [0x0407] = 'deDE',
    [0x040c] = 'frFR',
    [0x0c0a] = 'esES',
    [0x0410] = 'itIT',
    [0x0415] = 'plPL',
}

local tag_to_lcid = {}
for lcid, tag in pairs(lcid_to_tag) do
    tag_to_lcid[tag:lower()] = lcid
end

function m.lcid_to_tag(lcid)
    if not lcid then return 'default' end
    if lcid_to_tag[lcid] then
        return lcid_to_tag[lcid]
    end
    return ('loc_%04x'):format(lcid)
end

function m.tag_to_lcid(tag)
    if type(tag) == 'number' then
        return tag
    end
    if type(tag) ~= 'string' then
        return nil
    end
    local lower = tag:lower()
    if tag_to_lcid[lower] then
        return tag_to_lcid[lower]
    end
    local hex = lower:match('^loc_(%x+)$') or lower:match('^0x(%x+)$') or (lower:match('^%x%x%x%x$') and lower)
    if hex then
        return tonumber(hex, 16)
    end
    return nil
end

function m.is_locale_tag(key)
    if type(key) ~= 'string' then
        return false
    end
    if key:sub(1, 1) == '_' then
        return false
    end
    return m.tag_to_lcid(key) ~= nil
end

function m.is_localized_table(tbl)
    if type(tbl) ~= 'table' then
        return false
    end
    for k in pairs(tbl) do
        if m.is_locale_tag(k) then
            return true
        end
    end
    return false
end

function m.has_any_locale(tbl)
    if type(tbl) ~= 'table' then
        return false
    end
    if m.is_localized_table(tbl) then
        return true
    end
    for _, v in pairs(tbl) do
        if type(v) == 'table' and m.has_any_locale(v) then
            return true
        end
    end
    return false
end

function m.get_default_text(val)
    if type(val) ~= 'table' then
        return val
    end
    if val[1] ~= nil then
        return val[1]
    end
    if val['default'] ~= nil then
        return val['default']
    end
    for k, v in pairs(val) do
        if type(v) == 'string' or type(v) == 'table' then
            return v
        end
    end
    return ''
end

function m.get_locales(val)
    if type(val) ~= 'table' then
        return {}
    end
    local list = {}
    for k, v in pairs(val) do
        if m.is_locale_tag(k) and (type(v) == 'string' or type(v) == 'table') then
            local lcid = m.tag_to_lcid(k)
            if lcid and lcid ~= 0 then
                list[#list+1] = {
                    tag = k,
                    lcid = lcid,
                    text = v,
                }
            end
        end
    end
    table.sort(list, function(a, b) return a.tag < b.tag end)
    return list
end

-- Convert level-first repeated tables into a locale-first table
-- e.g. { [1] = { [1] = "def 1", zhTW = "tw 1" }, [2] = { [1] = "def 2", zhTW = "tw 2" } }
--   => { [1] = { "def 1", "def 2" }, zhTW = { "tw 1", "tw 2" } }
function m.to_locale_first(levels)
    if type(levels) ~= 'table' or m.is_localized_table(levels) then
        return levels
    end
    local active_tags = {}
    local max_level = 0
    for lvl, val in pairs(levels) do
        if type(lvl) == 'number' and lvl > max_level then
            max_level = lvl
        end
        if type(val) == 'table' and m.is_localized_table(val) then
            for _, info in ipairs(m.get_locales(val)) do
                active_tags[info.tag] = true
            end
        end
    end
    if not next(active_tags) then
        return levels
    end

    local res = {}
    local def_list = {}
    for lvl = 1, max_level do
        local val = levels[lvl]
        if type(val) == 'table' and m.is_localized_table(val) then
            def_list[lvl] = m.get_default_text(val)
        else
            def_list[lvl] = val or ''
        end
    end
    res[1] = def_list

    for tag in pairs(active_tags) do
        local loc_list = {}
        for lvl = 1, max_level do
            local val = levels[lvl]
            if type(val) == 'table' and m.is_localized_table(val) and val[tag] ~= nil then
                loc_list[lvl] = val[tag]
            else
                loc_list[lvl] = def_list[lvl]
            end
        end
        res[tag] = loc_list
    end
    return res
end

-- Normalize repeated data from any format (locale-first, level-first, or plain array)
-- into a level array where each element is either a scalar or a localized table
function m.normalize_repeated_data(data)
    if type(data) ~= 'table' then
        return { data }
    end
    -- Case 1: Locale-first table, e.g. { [1] = { "def1", "def2" }, zhTW = { "tw1", "tw2" } }
    if m.is_localized_table(data) then
        local def_list = data[1] or data['default']
        if type(def_list) == 'table' then
            local max_level = 0
            for k in pairs(def_list) do
                if type(k) == 'number' and k > max_level then
                    max_level = k
                end
            end
            for _, loc in ipairs(m.get_locales(data)) do
                if type(loc.text) == 'table' then
                    for k in pairs(loc.text) do
                        if type(k) == 'number' and k > max_level then
                            max_level = k
                        end
                    end
                end
            end
            local levels = {}
            for lvl = 1, max_level do
                local lvl_table = { [1] = def_list and def_list[lvl] }
                local has_loc = false
                for _, loc in ipairs(m.get_locales(data)) do
                    if type(loc.text) == 'table' and loc.text[lvl] ~= nil then
                        lvl_table[loc.tag] = loc.text[lvl]
                        has_loc = true
                    end
                end
                if has_loc then
                    levels[lvl] = lvl_table
                else
                    levels[lvl] = lvl_table[1]
                end
            end
            return levels
        else
            -- Single localized value for 1 level: { [1] = "def", zhTW = "tw" }
            return { data }
        end
    end
    -- Case 2: Standard or level-first array, e.g. { [1] = ..., [2] = ... }
    return data
end

local function format_single_string(value, get_editstring)
    if type(value) ~= 'string' then
        value = tostring(value or '')
    end
    if get_editstring then
        value = get_editstring(value)
    end
    if value:match('[\n\r]') then
        return ('[=[\r\n%s]=]'):format(value)
    else
        return ('%q'):format(value)
    end
end
m.format_single_string = format_single_string

local function format_val_or_list(value, indent, get_editstring)
    if type(value) == 'table' then
        local sub_indent = indent .. '    '
        local sub_lines = {}
        for i = 1, #value do
            sub_lines[#sub_lines+1] = ('%s%s,'):format(sub_indent, format_single_string(value[i], get_editstring))
        end
        return ('{\r\n%s\r\n%s}'):format(table.concat(sub_lines, '\r\n'), indent)
    else
        return format_single_string(value, get_editstring)
    end
end
m.format_val_or_list = format_val_or_list

function m.format_localized_value(tbl, indent, get_editstring)
    indent = indent or ''
    local lines = {}
    local def_text = m.get_default_text(tbl)
    local def_formatted = format_val_or_list(def_text, indent .. '    ', get_editstring)
    lines[#lines+1] = ('%s    %s,'):format(indent, def_formatted)
    
    local locales = m.get_locales(tbl)
    for _, loc in ipairs(locales) do
        local loc_formatted = format_val_or_list(loc.text, indent .. '    ', get_editstring)
        lines[#lines+1] = ('%s    %s = %s,'):format(indent, loc.tag, loc_formatted)
    end
    return ('{\r\n%s\r\n%s}'):format(table.concat(lines, '\r\n'), indent)
end

return m
