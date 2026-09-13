local lang = require 'lang'
local w2l
local is_remove_exceeds_level
local metadata

local pairs = pairs
local type = type
local assert = assert

local locale_util = require 'locale_util'

local function maxindex(t)
    local i = 0
    for k in pairs(t) do
        if k > i then
            i = k
        end
    end
    return i
end

local function fill_and_copy(a, lv)
    local has_locale = locale_util.has_any_locale(a)
    if has_locale then
        a = locale_util.normalize_repeated_data(a)
    end
    local c = {}
    if #a < lv then
        for i = 1, #a do
            c[i] = a[i]
        end
        for i = #a+1, lv do
            c[i] = a[#a]
        end
    else
        for i = 1, lv do
            c[i] = a[i]
        end
    end
    if not is_remove_exceeds_level then
        local maxlv = maxindex(a)
        if maxlv > lv then
            for i = lv+1, maxlv do
                c[i] = a[i] or a[#a]
            end
        end
    end
    if has_locale then
        return locale_util.to_locale_first(c)
    end
    return c
end

local function fill_and_merge(a, b, lv, meta)
    local has_locale = locale_util.has_any_locale(a) or locale_util.has_any_locale(b)
    if has_locale then
        a = locale_util.normalize_repeated_data(a)
        b = locale_util.normalize_repeated_data(b)
    end
    local c = {}
    if #a < lv then
        for i = 1, #a do
            c[i] = b[i] or a[i]
        end
        if meta and meta.appendindex then
            for i = #a+1, lv do
                c[i] = b[i] or ''
            end
        elseif not meta or meta.profile then
            local maxlv = maxindex(b)
            for i = #a+1, lv do
                if i > maxlv then
                    c[i] = b[i] or c[i-1]
                else
                    c[i] = b[i] or ''
                end
            end
        else
            for i = #a+1, lv do
                c[i] = b[i] or a[#a]
            end
        end
    else
        for i = 1, lv do
            c[i] = b[i] or a[i]
        end
    end
    if not is_remove_exceeds_level then
        local maxlv = maxindex(b)
        if maxlv > lv then
            for i = lv+1, maxlv do
                c[i] = b[i] or a[#a]
            end
        end
    end
    if has_locale then
        return locale_util.to_locale_first(c)
    end
    return c
end

local function get_meta(code, ttype, k)
    if code and metadata[code] and metadata[code][k] then
        return metadata[code][k]
    end
    if ttype and metadata[ttype] and metadata[ttype][k] then
        return metadata[ttype][k]
    end
    return nil
end

local function copy_obj(a, b, ttype)
    local c = {}
    local lv = tonumber(b._max_level or a._max_level)
    if lv and lv > 10000 then
        lv = 10000
    end
    if b._code and a._code ~= b._code then
        w2l.messager.report(lang.report.INVALID_OBJECT_DATA, 6, lang.report.ABILITY_CODE_ERROR:format(b._id, b._code), lang.report.DEFAULT_IS:format(a._code))
        return nil
    end
    for k, v in pairs(a) do
        local meta = get_meta(b._code or a._code, ttype or a._type or b._type, k)
        if b[k] then
            if type(v) == 'table' then
                if meta and not meta['repeat'] and locale_util.is_localized_table(b[k]) then
                    c[k] = b[k]
                else
                    c[k] = fill_and_merge(v, b[k], lv, meta)
                end
            else
                c[k] = b[k]
            end
            b[k] = nil
        else
            if type(v) == 'table' then
                if meta and not meta['repeat'] and locale_util.is_localized_table(v) then
                    c[k] = v
                else
                    c[k] = fill_and_copy(v, lv)
                end
            else
                c[k] = v
            end
        end
    end
    for k, v in pairs(b) do
        -- txt中读取出来的数据有等级
        c[k] = v
    end
    return c
end

local function fill_obj(a, ttype)
    local c = {}
    local lv = a._max_level
    if lv and lv > 10000 then
        lv = 10000
    end
    for k, v in pairs(a) do
        local meta = get_meta(a._code, ttype or a._type, k)
        if type(v) == 'table' then
            if meta and not meta['repeat'] and locale_util.is_localized_table(v) then
                c[k] = v
            else
                c[k] = fill_and_copy(v, lv)
            end
        else
            c[k] = v
        end
    end
    return c
end

return function (w2l_, type, data, objs)
    w2l = w2l_
    if type == 'txt' then
        is_remove_exceeds_level = false
    else
        is_remove_exceeds_level = true
    end
    metadata = w2l:metadata()
    local template = {}
    local result = {}
    for name, obj in pairs(objs) do
        local source = data[name]
        if source then
            template[name] = source
            data[name] = nil
        else
            source = template[obj._parent] or data[obj._parent]
        end
        if source then
            result[name] = copy_obj(source, obj, type)
        else
            assert(type == 'txt')
            result[name] = obj
        end
    end
    for name, obj in pairs(data) do
        result[name] = fill_obj(obj, type)
    end
    return result
end
