-- Canonical locale sources. Locale IDs are metadata, not MPQ filenames.
local m = {}

-- These source files have one owner, even in a neutral-only map.
function m.managed(name)
    name = name:lower():gsub('/', '\\')
    return name:match('^units\\') ~= nil
        or name == 'war3map.wts' or name == 'war3campaign.wts'
end

function m.validate(name)
    assert(name ~= '' and not name:match('^[\\/]'), 'Invalid locale member path: ' .. name)
    for component in name:gmatch('[^\\/]+') do
        assert(component ~= '.' and component ~= '..', 'Unsafe locale member path: ' .. name)
    end
end

function m.collect(input)
    if input:get_type() == 'dir' then
        local entries = input.handle:localized_files()
        local seen = {}
        for _, entry in ipairs(entries) do
            if entry.locale == 0 then seen[entry.name:lower()] = true end
        end
        -- Accept legacy neutral files as input, but emit only the new layout.
        for _, name in ipairs(input:list_file()) do
            local source = name:gsub('^[Mm][Aa][Pp]\\', '')
            if m.managed(source) and not seen[source:lower()] then
                m.validate(source)
                entries[#entries+1] = {name = source, locale = 0,
                    buf = assert(input:get(name))}
                seen[source:lower()] = true
            end
        end
        return entries
    end
    local names = {}
    for name in (input:get('(listfile)') or ''):gmatch('[^\r\n]+') do
        names[name:lower()] = name
    end
    for key, name in pairs(input.case) do names[key] = name end
    local entries = {}
    for _, name in pairs(names) do
        local locales = input.handle:locales(name)
        if #locales > 0 then
            assert(not name:lower():match('^locales[\\/]'),
                'MPQ member conflicts with reserved locales directory: ' .. name)
        end
        for _, locale in ipairs(locales) do
            if locale ~= 0 or m.managed(name) then
                m.validate(name)
                entries[#entries+1] = {
                    name = name, locale = locale,
                    buf = assert(input.handle:load_locale(name, locale),
                        'Cannot read MPQ locale: ' .. name),
                }
            end
        end
    end
    table.sort(entries, function(a, b)
        if a.name ~= b.name then return a.name < b.name end
        return a.locale < b.locale
    end)
    return entries
end

function m.path(entry)
    m.validate(entry.name)
    return ('locales\\%04X\\%s'):format(entry.locale, entry.name)
end

return m
