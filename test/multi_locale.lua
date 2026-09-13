-- From script/: ../bin/w3x2lni-lua.exe ../test/multi_locale.lua MODE INPUT OUTPUT
package.path = './?.lua;./?/init.lua;' .. package.path
package.cpath = '../bin/?.dll;' .. package.cpath
require 'utility'
local fs = require 'bee.filesystem'
local storm = require 'ffi.stormlib'
local ffi = require 'ffi'
local lib = ffi.load('stormlib')
local action, source, target = arg[1], fs.path(assert(arg[2])), arg[3] and fs.path(arg[3])
local internal = {['(listfile)']=true, ['(attributes)']=true, ['(signature)']=true}

if action == 'seed' then
    fs.create_directories(source:parent_path())
    assert(io.save(source, ''))
    local ar = assert(storm.create(source, 32))
    for _, locale in ipairs {0, 0x404, 0x409, 0x412, 0x411} do
        assert(ar:save_file('Units\\CampaignAbilityStrings.txt',
            ('[A000]\r\nTip=語言 언어 %04X\r\n'):format(locale), 0, locale))
    end
    assert(ar:save_file('only-korean.txt', '\239\187\191한국어\0end', 0, 0x412))
    assert(ar:save_file('empty.txt', '', 0, 0x409))
    assert(ar:save_file('common.bin', '\0\255\1', 0, 0))
    ar:close()
    ar = assert(storm.open(source, true))
    local previous = lib.SFileSetLocale(0x409)
    assert(ar:load_file('only-korean.txt', 0) == nil)
    assert(ar:load_file('common.bin', 0x412) == nil) -- no fallback for exact reads
    assert(ar:load_file('empty.txt', 0x409) == '')
    assert(ar:load_file('Units\\CampaignAbilityStrings.txt', 0):find('0000'))
    assert(tonumber(lib.SFileGetLocale()) == 0x409)
    lib.SFileSetLocale(previous)
    ar:close()
    print('PASS seed, exact locales, empty/binary/UTF-8, global locale restored')
elseif action == 'invalid' then
    local dir = require('map-builder.archive_dir')(source, true)
    assert(not pcall(function() dir:localized_files() end), 'Invalid locale directory accepted')
    local validate = require('map-builder.locales').validate
    assert(not pcall(validate, '..\\escape.txt'))
    assert(not pcall(validate, '\\absolute.txt'))
    print('PASS invalid locale directories and unsafe member paths rejected')
elseif action == 'overlay' then
    local dir = require('map-builder.archive_dir')(source, true)
    local ar = assert(storm.open(target, true))
    local entries = dir:localized_files()
    for _, entry in ipairs(entries) do
        assert(ar:load_file(entry.name, entry.locale) == entry.buf, entry.name)
    end
    ar:close()
    print('PASS packed raw overlays: ' .. #entries)
elseif action == 'compare' or action == 'folder' then
    local original = assert(storm.open(source, true))
    local rebuilt = action == 'compare' and assert(storm.open(target, true))
    local dir = action == 'folder' and require('map-builder.archive_dir')(target, true)
    local count, expected = 0, {}
    for name in assert(original:load_file('(listfile)', 0)):gmatch('[^\r\n]+') do
        if not internal[name:lower()] then
            local locales = original:locales(name)
            if rebuilt then
                assert(table.concat(locales, ',') == table.concat(rebuilt:locales(name), ','), name)
            end
            for _, locale in ipairs(locales) do
                local buf = assert(original:load_file(name, locale))
                local actual
                if rebuilt then
                    actual = rebuilt:load_file(name, locale)
                else
                    local path = name
                    if locale ~= 0 or require('map-builder.locales').managed(name) then
                        path = ('locales\\%04X\\%s'):format(locale, name)
                        if locale == 0 then
                            assert(not fs.exists(target / name), 'Duplicate neutral source: ' .. name)
                            assert(not fs.exists(target / 'map' / name), 'Duplicate map source: ' .. name)
                        end
                    elseif arg[4] == 'lni' then
                        -- Normal LNI members are transformed; only verify raw overlays here.
                        path = nil
                    end
                    if path then actual = dir:load_file(path) else actual = buf end
                end
                assert(actual == buf, ('Payload mismatch: %s / %04X'):format(name, locale))
                expected[name:lower()] = true
                count = count + 1
            end
        end
    end
    if rebuilt then
        for name in assert(rebuilt:load_file('(listfile)', 0)):gmatch('[^\r\n]+') do
            assert(not name:lower():match('^locales\\'), 'Directory leaked into MPQ: ' .. name)
            if arg[4] ~= 'overlays' then
                assert(internal[name:lower()] or expected[name:lower()], 'Unexpected member: ' .. name)
            end
        end
        rebuilt:close()
    end
    original:close()
    print('PASS ' .. action .. ': ' .. count .. ' original member/locale payloads')
else
    error('Unknown action: ' .. tostring(action))
end
