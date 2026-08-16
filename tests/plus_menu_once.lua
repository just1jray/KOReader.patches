-- Reproduces plus-menu extras stacking when Project: Title is instantiated
-- more than once (FileManager start, then Reader, then FileManager again).
-- KOReader's userpatch.registerPatchPluginFunc runs on every createPluginInstance.

local patch_file = arg[1] or "2-pt-titlebar.lua"

package.preload["gettext"] = function()
    return function(s) return s end
end

package.preload["dispatcher"] = function()
    return {
        getNameFromItem = function() return "Unknown item" end,
        execute = function() end,
    }
end

package.preload["ui/widget/infomessage"] = function()
    return { new = function() return {} end }
end

package.preload["ui/uimanager"] = function()
    return { show = function() end, close = function() end }
end

package.preload["titlebar"] = function()
    return { init = function() end }
end

local FileManager = {
    instance = {},
    getPlusDialogButtons = function()
        return "Plus", {
            { { text = "Select files" } },
            { { text = "New folder" } },
        }
    end,
}
package.preload["apps/filemanager/filemanager"] = function()
    return FileManager
end

local patch_plugin_func
package.preload["userpatch"] = function()
    return {
        registerPatchPluginFunc = function(_, func)
            patch_plugin_func = func
        end,
    }
end

assert(loadfile(patch_file))()
assert(patch_plugin_func, "patch did not register a plugin func")

-- Simulate FileManager + Reader instantiations of projecttitle.
patch_plugin_func({})
patch_plugin_func({})

local _, buttons = FileManager.getPlusDialogButtons({})
local extras = {}
for _, row in ipairs(buttons) do
    local btn = row[1]
    if btn and btn.text then
        extras[btn.text] = (extras[btn.text] or 0) + 1
    end
end

local function expect_once(label)
    local n = extras[label] or 0
    if n ~= 1 then
        error(string.format("%q appears %d time(s), expected 1", label, n))
    end
end

expect_once("Anna's Archive")
expect_once("AppStore")
expect_once("Z-Library")
print("ok: plus-menu extras appear once after two plugin instantiations")
