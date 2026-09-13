local lang = require 'share.lang'
local fs = require 'bee.filesystem'

return function (w2l, w3i, w3f, input_ar, output_ar, args)
    input_ar:close()
    if w2l.setting.mode == 'lni' then
        output_ar.localized = nil
        if output_ar:get_type() == 'dir' and output_ar.handle and output_ar.handle.path then
            local loc_dir = output_ar.handle.path / 'locales'
            if fs.exists(loc_dir) then
                fs.remove_all(loc_dir)
            end
        end
        output_ar:flush()
    else
        if w2l.slk and w2l.slk.localized_files then
            output_ar.localized = w2l.slk.localized_files
        end
    end
    local suc, res = output_ar:save(w3i, w3f, w2l, args)
    if not suc then
        w2l:failed(res or lang.script.CREATE_FAILED)
    end
    output_ar:close()
end
