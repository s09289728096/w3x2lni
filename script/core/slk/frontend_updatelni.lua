local type = type
local locale_util = require 'locale_util'

local w2l
local metadata
local slk_type

local function check_repeat(obj, key, meta)
    if not obj[key] or not meta['repeat'] then
        return
    end
    if type(obj[key]) ~= 'table' then
        obj[key] = {obj[key]}
    elseif locale_util.is_localized_table(obj[key]) then
        local def = obj[key][1] or obj[key]['default']
        if type(def) ~= 'table' then
            obj[key] = {obj[key]}
        end
    end
end

local function update_obj(ttype, name, obj, data)
    local parent = obj._parent
    local temp = data[parent]
    local code = temp._code
    obj._code = code
    for key, meta in pairs(metadata[ttype]) do
        check_repeat(obj, key, meta)
    end
    if metadata[code] then
        for key, meta in pairs(metadata[code]) do
            check_repeat(obj, key, meta)
        end
    end
end

local function update_txt(obj)
    for k, v in pairs(obj) do
        if type(v) ~= 'table' then
            obj[k] = {v}
        end
    end
end

local function update_reforge(lni)
    if w2l:isreforge() then
        for name, obj in pairs(lni) do
            for k, meta in pairs(metadata[slk_type]) do
                if not obj[k] and meta.reforge then
                    obj[k] = obj[meta.reforge]
                end
            end
        end
    end
end

return function(w2l_, type, lni, data)
    w2l = w2l_
    slk_type = type
    if type == 'txt' then
        for _, obj in pairs(lni) do
            update_txt(obj)
        end
        return
    end
    metadata = w2l:metadata()
    update_reforge(lni)
    local has_level = w2l.info.key.max_level[type]
    if not has_level then
        return
    end
    for name, obj in pairs(lni) do
        update_obj(type, name, obj, data)
    end
end
