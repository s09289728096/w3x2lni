-- End-to-end regression test for the LNI multi-locale contract in docs/multi-locale.md.
-- Run from the repository root: bin\w3x2lni-lua.exe test\i18n_integration.lua

local fs = require 'bee.filesystem'
local source = debug.getinfo(1, 'S').source
local test_file = fs.path(source:sub(1, 1) == '@' and source:sub(2) or source)
local root = fs.absolute(test_file:parent_path():parent_path())

package.path = (root / 'script' / '?.lua'):string() .. ';'
    .. (root / 'script' / '?' / 'init.lua'):string() .. ';' .. package.path
package.cpath = (root / 'bin' / '?.dll'):string() .. ';' .. package.cpath

require 'utility'

local storm = require 'ffi.stormlib'
local subprocess = require 'bee.subprocess'
local thread = require 'bee.thread'
local lang = require 'share.lang'

local locales = { default = 0x0000, zhTW = 0x0404, enUS = 0x0409, koKR = 0x0412 }
local work = root / 'build' / 'test-i18n'

local function read(path)
    local file = assert(io.open(path:string(), 'rb'))
    local value = assert(file:read '*a')
    file:close()
    return value
end

local function write(path, value)
    local file = assert(io.open(path:string(), 'wb'))
    assert(file:write(value))
    file:close()
end

local function remove_tree(path)
    local last_error
    for _ = 1, 100 do
        local ok, err = pcall(fs.remove_all, path)
        if ok then return end
        last_error = err
        thread.sleep(0.05)
    end
    error(last_error)
end

local function contains(value, text, context)
    assert(value:find(text, 1, true), ('Missing %q in %s'):format(text, context))
end

local function w2l(...)
    local args = {...}
    local process = assert(subprocess.spawn {
        root / 'w2l.exe', args, cwd = root, hideWindow = true, stdout = true, stderr = true,
    })
    local exit_code = process:wait()
    local stdout = process.stdout:read 'a' or ''
    local stderr = process.stderr:read 'a' or ''
    assert(exit_code == 0, ('w2l %s failed (%d)\nstdout:\n%s\nstderr:\n%s')
        :format(table.concat(args, ' '), exit_code, stdout, stderr))
end

local function write_fixture(path)
    local w = lang.w3i
    fs.create_directories(path / 'map')
    fs.create_directories(path / 'table')
    write(path / '.w3x', '\0\0\0\0\0\0\0\0W2L\1\0\0\0\0')
    write(path / 'map' / 'war3map.j',
        'function main takes nothing returns nothing\r\nendfunction\r\n'
        .. 'function config takes nothing returns nothing\r\nendfunction\r\n')

    write(path / 'table' / 'w3i.ini', table.concat({
        '[' .. w.MAP .. ']', w.FILE_VERSION .. ' = 25', w.MAP_VERSION .. ' = 1', w.WE_VERSION .. ' = 6050',
        w.MAP_NAME .. ' = {\r\n    "Neutral map",\r\n    enUS = "English map",\r\n    zhTW = "Traditional map",\r\n    koKR = "Korean map",\r\n}',
        w.AUTHOR_NAME .. ' = {\r\n    "Neutral author",\r\n    enUS = "English author",\r\n}',
        w.MAP_DESC .. ' = {\r\n    "Neutral description",\r\n    enUS = "English description",\r\n    koKR = "Korean description",\r\n}',
        w.PLAYER_DESC .. ' = "1v1"', '',
        '[' .. w.CAMERA .. ']', w.CAMERA_BOUND .. ' = {-5376.0000, -5888.0000, 5376.0000, 5376.0000, -5376.0000, 5376.0000, 5376.0000, -5888.0000}', w.CAMERA_COMPLEMENT .. ' = {18, 18, 16, 20}', '',
        '[' .. w.MAP_INFO .. ']', w.MAP_WIDTH .. ' = 92', w.MAP_HEIGHT .. ' = 92', w.MAP_MAIN_GROUND .. ' = "L"', '',
        '[' .. w.CONFIG .. ']', w.GAME_DATA_SETTING .. ' = 0', w.DISABLE_PREVIEW .. ' = 0', w.CUSTOM_ALLY .. ' = 0', w.MELEE_MAP .. ' = 1', w.LARGE_MAP .. ' = 1', w.MASKED_AREA_SHOW_TERRAIN .. ' = 1', w.FIX_FORCE_SETTING .. ' = 0', w.CUSTOM_FORCE .. ' = 0', w.CUSTOM_TECHTREE .. ' = 0', w.CUSTOM_ABILITY .. ' = 0', w.CUSTOM_UPGRADE .. ' = 0', w.MAP_MENU_MARK .. ' = 1', w.SHOW_WAVE_ON_CLIFF .. ' = 1', w.SHOW_WAVE_ON_ROLLING .. ' = 1', w.UNKNOWN_1 .. ' = 1', w.UNKNOWN_2 .. ' = 1', w.UNKNOWN_3 .. ' = 1', w.UNKNOWN_4 .. ' = 0', w.UNKNOWN_5 .. ' = 0', w.UNKNOWN_6 .. ' = 0', w.UNKNOWN_7 .. ' = 0', w.UNKNOWN_8 .. ' = 0', w.UNKNOWN_9 .. ' = 0', '',
        '[' .. w.LOADING_SCREEN .. ']', w.ID .. ' = -1', w.PATH .. ' = ""', w.TEXT .. ' = ""', w.TITLE .. ' = ""', w.SUBTITLE .. ' = ""', '',
        '[' .. w.PROLOGUE .. ']', w.PATH .. ' = ""', w.TEXT .. ' = ""', w.TITLE .. ' = ""', w.SUBTITLE .. ' = ""', '',
        '[' .. w.FOG .. ']', w.TYPE .. ' = 0', w.START_Z .. ' = 2000.0000', w.END_Z .. ' = 4000.0000', w.DENSITY .. ' = 0.5000', w.COLOR .. ' = {128, 128, 128, 255}', '',
        '[' .. w.ENVIRONMENT .. ']', w.WEATHER .. ' = "RAlr"', w.SOUND .. ' = ""', w.LIGHT .. ' = "\\0"', w.WATER_COLOR .. ' = {255, 255, 255, 255}', '',
        '[' .. w.PLAYER .. ']', w.PLAYER_COUNT .. ' = 1', '',
        '[' .. w.PLAYER .. '1]', w.PLAYER .. ' = 0', w.TYPE .. ' = 1', w.RACE .. ' = 1', w.FIX_START_POSITION .. ' = 0', w.NAME .. ' = "Player 1"', w.START_POSITION .. ' = {0.0000, 0.0000}', w.ALLY_LOW_FLAG .. ' = {}', w.ALLY_HIGH_FLAG .. ' = {}', '',
        '[' .. w.FORCE .. ']', w.FORCE_COUNT .. ' = 1', '',
        '[' .. w.FORCE .. '1]', w.ALLY .. ' = 0', w.ALLY_WIN .. ' = 0', w.SHARE_VISIBLE .. ' = 0', w.SHARE_CONTROL .. ' = 0', w.SHARE_ADVANCE .. ' = 0', w.PLAYER_LIST .. ' = {1}', w.FORCE_NAME .. ' = "Force 1"', '',
    }, '\r\n'))

    write(path / 'table' / 'ability.ini', [==[
[AHtb]
_parent = "AHtb"
Name = { "Neutral ability", enUS = "English ability", zhTW = "Traditional ability", koKR = "Korean ability" }
Tip = {
    { "Neutral tip level 1", "Neutral tip level 2" },
    enUS = { "English tip level 1", "English tip level 2" },
    zhTW = { "Traditional tip level 1", "Traditional tip level 2" },
    koKR = { "Korean tip level 1", "Korean tip level 2" },
}
Ubertip = {
    { [=[Neutral multiline tooltip]=] },
    enUS = { [=[English multiline tooltip]=] },
    zhTW = { [=[Traditional multiline tooltip]=] },
    koKR = { [=[Korean multiline tooltip]=] },
}
]==])
end

local function assert_wts(map, mode)
    local archive = assert(storm.open(map, true))
    local found = {}
    for _, lcid in ipairs(archive:locales 'war3map.wts') do found[lcid] = true end
    for tag, lcid in pairs(locales) do
        assert(found[lcid], ('%s map is missing %s WTS (0x%04X)'):format(mode, tag, lcid))
    end
    local ability_member = mode == 'slk' and 'Units\\CampaignAbilityStrings.txt' or 'war3map.wts'
    for lcid, text in pairs { [locales.enUS] = 'English ability', [locales.zhTW] = 'Traditional ability', [locales.koKR] = 'Korean ability' } do
        contains(assert(archive:load_file(ability_member, lcid)), text, mode .. ' ability strings')
    end
    if mode == 'slk' then
        for lcid, text in pairs { [locales.enUS] = 'English map', [locales.zhTW] = 'Traditional map', [locales.koKR] = 'Korean map' } do
            contains(assert(archive:load_file('war3map.wts', lcid)), text, mode .. ' map WTS')
        end
    end
    archive:close()
end

local function assert_lni(path, mode)
    assert(not fs.exists(path / 'locales'), mode .. ' unpack leaked a locales directory')
    local ability, w3i = read(path / 'table' / 'ability.ini'), read(path / 'table' / 'w3i.ini')
    for _, text in ipairs {'English ability', 'Traditional ability', 'Korean ability', 'English tip level 2', 'Traditional multiline tooltip'} do
        contains(ability, text, mode .. ' ability round trip')
    end
    for _, text in ipairs {'English map', 'Traditional map', 'Korean map'} do
        contains(w3i, text, mode .. ' map-info round trip')
    end
end

local ok, err = xpcall(function()
    remove_tree(work)
    fs.create_directories(work)
    local input = work / 'input'
    write_fixture(input)
    for _, mode in ipairs {'obj', 'slk'} do
        local map, unpacked = work / (mode .. '.w3x'), work / (mode .. '-lni')
        if mode == 'slk' then
            w2l(mode, input:string(), map:string(), '-remove_we_only=false', '-remove_unuse_object=false')
        else
            w2l(mode, input:string(), map:string())
        end
        assert(fs.exists(map), mode .. ' did not create a map')
        assert_wts(map, mode)
        w2l('lni', map:string(), unpacked:string())
        assert_lni(unpacked, mode)
        print('PASS i18n ' .. mode .. ' -> lni round trip')
    end
end, debug.traceback)
local cleanup_ok, cleanup_err = pcall(remove_tree, work)
assert(ok, err)
assert(cleanup_ok, cleanup_err)
print 'PASS i18n integration test'
