--[[
 Project: Title user patch — titlebar slots + plus-menu plugin rows.

 Requires stock Project: Title 3.8+ (not the just1jray fork).

 Install:
   1. Copy this file to koreader/patches/2-pt-titlebar.lua
   2. Copy patches/icons/*.svg to koreader/icons/ (skip names that already exist)
   3. Restart KOReader

 Edit SLOTS and PLUS_MENU below, then restart.
 right1 (plus / select-mode check) is not configurable.

 Layout below was read from this Kindle's PT_bookinfo_cache.sqlite3 config table.
--]]

local userpatch = require("userpatch")
local FileManager = require("apps/filemanager/filemanager")
local ConfirmBox = require("ui/widget/confirmbox")
local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local _ = require("gettext")

-- =========================== CONFIG ===========================
-- Action ids: home, favorites, history, last_document, go_up, go_root,
-- collections, meta_browse, exit, manga, annas, zlib, appstore, opds, none

local SLOTS = {
    left1  = { tap = "go_up",          hold = "go_root" },
    left2  = { tap = "history",        hold = "collections" },
    left3  = { tap = "manga",          hold = "opds" },
    center = { tap = "home",           hold = "annas", force_hero = true },
    right3 = { tap = "favorites",      hold = "none" },
    right2 = { tap = "last_document",  hold = "none" },
}

local PLUS_MENU = { "annas", "appstore", "zlib" }
-- ========================= END CONFIG =========================

local SLOT_ORDER = { "left1", "left2", "left3", "center", "right3", "right2" }

local function fm()
    return FileManager.instance
end

local function info(text)
    UIManager:show(InfoMessage:new { text = text })
end

local function pluginOrNil(instance, keys)
    if not instance then return nil end
    for _, key in ipairs(keys) do
        if instance[key] then return instance[key] end
    end
    return nil
end

local function favoritesTap()
    local instance = fm()
    if instance and instance.collections then
        instance.collections:onShowColl()
    end
end

local function favoritesHold()
    local instance = fm()
    if instance and instance.folder_shortcuts then
        instance.folder_shortcuts:onShowFolderShortcutsDialog()
    end
end

local ACTIONS = {
    home = {
        icon = "home",
        tap = function()
            local instance = fm()
            if instance then instance:onHome() end
        end,
        hold = function()
            local instance = fm()
            if instance then instance:onShowFolderMenu() end
        end,
    },
    favorites = {
        icon = "favorites",
        tap = favoritesTap,
        hold = favoritesHold,
    },
    history = {
        icon = "history",
        tap = function()
            local instance = fm()
            if instance and instance.history then instance.history:onShowHist() end
        end,
    },
    last_document = {
        icon = "last_document",
        tap = function()
            local instance = fm()
            if instance and instance.menu then instance.menu:onOpenLastDoc() end
        end,
    },
    go_up = {
        icon = "go_up",
        tap = function()
            local instance = fm()
            if not instance or not instance.file_chooser then return end
            local path = instance.file_chooser.path
            if not path then return end
            if G_reader_settings:isTrue("lock_home_folder")
                and path == G_reader_settings:readSetting("home_dir") then
                return
            end
            instance.file_chooser:changeToPath(string.format("%s/..", path), path)
        end,
    },
    go_root = {
        icon = "go_root",
        tap = function()
            local instance = fm()
            if not instance or not instance.file_chooser then return end
            if G_reader_settings:isTrue("lock_home_folder") then
                local home_dir = G_reader_settings:readSetting("home_dir")
                if home_dir then instance.file_chooser:changeToPath(home_dir) end
            else
                instance.file_chooser:changeToPath("/")
            end
        end,
    },
    collections = {
        icon = "tab_collections",
        tap = function()
            local instance = fm()
            if instance and instance.collections then
                instance.collections:onShowCollList()
            end
        end,
    },
    manga = {
        icon = "tab_manga",
        tap = function()
            local instance = fm()
            if instance and instance.rakuyomi then
                instance.rakuyomi:openLibraryView()
            else
                info(_("Rakuyomi plugin not found."))
            end
        end,
    },
    annas = {
        icon = "tab_books",
        tap = function()
            local instance = fm()
            local plugin = pluginOrNil(instance, {
                "annas_archive", "annas-archive", "annasarchive", "Anna's Archive",
            })
            if plugin and plugin.showMultiSearchDialog then
                plugin:showMultiSearchDialog()
            elseif plugin and plugin.showSearchDialog then
                plugin:showSearchDialog()
            elseif plugin and plugin.onZlibrarySearch then
                plugin:onZlibrarySearch()
            else
                info(_("Anna's Archive plugin not found."))
            end
        end,
    },
    zlib = {
        icon = "tab_news",
        tap = function()
            local instance = fm()
            local plugin = pluginOrNil(instance, {
                "Z-library", "Z-Library", "z-library", "zlibrary",
            })
            if plugin and plugin.showMultiSearchDialog then
                plugin:showMultiSearchDialog()
            else
                info(_("Z-Library plugin not found."))
            end
        end,
    },
    appstore = {
        icon = "tab_continue",
        tap = function()
            local instance = fm()
            if instance and instance.appstore then
                instance.appstore:showBrowser()
            else
                info(_("AppStore plugin not found."))
            end
        end,
    },
    opds = {
        icon = "tab_history",
        tap = function()
            local instance = fm()
            if instance and instance.opds then
                instance.opds:onShowOPDSCatalog()
            else
                info(_("OPDS plugin not found."))
            end
        end,
    },
    exit = {
        icon = "tab_exit",
        tap = function()
            local instance = fm()
            if not instance then return end
            local back_to_exit = G_reader_settings:readSetting("back_to_exit", "prompt")
            if back_to_exit == "always" then
                instance:onClose()
            else
                UIManager:show(ConfirmBox:new {
                    text = _("Exit KOReader?"),
                    ok_text = _("Exit"),
                    ok_callback = function() instance:onClose() end,
                })
            end
        end,
    },
    none = {},
}

local PLUS_LABELS = {
    manga = "Manga/Rakuyomi",
    annas = "Anna's Archive",
    zlib = "Z-Library",
    appstore = "AppStore",
    opds = "OPDS catalog",
}

local function applySlots(titlebar)
    for _, slot in ipairs(SLOT_ORDER) do
        local cfg = SLOTS[slot]
        if cfg then
            local tap_action = ACTIONS[cfg.tap] or ACTIONS.none
            local hold_action = ACTIONS[cfg.hold] or ACTIONS.none
            local icon = tap_action.icon or hold_action.icon
            if slot == "center" and (cfg.force_hero or not icon) then
                icon = "hero"
            end
            if icon then
                titlebar[slot .. "_icon"] = icon
            elseif cfg.tap == "none" and cfg.hold == "none" then
                titlebar[slot .. "_icon"] = nil
            end
            titlebar[slot .. "_icon_tap_callback"] = tap_action.tap or false
            titlebar[slot .. "_icon_hold_callback"] = hold_action.hold or false
        end
    end
end

local function patchProjectTitle(plugin)
    local TitleBar = require("titlebar")
    local orig_TitleBar_init = TitleBar.init
    TitleBar.init = function(self)
        applySlots(self)
        orig_TitleBar_init(self)
    end

    if PLUS_MENU and #PLUS_MENU > 0 then
        local orig_getPlus = FileManager.getPlusDialogButtons
        FileManager.getPlusDialogButtons = function(self)
            local title, buttons = orig_getPlus(self)
            local extras_added = false
            for _, id in ipairs(PLUS_MENU) do
                local action = ACTIONS[id]
                if action and action.tap then
                    if not extras_added then
                        table.insert(buttons, {})
                        extras_added = true
                    end
                    table.insert(buttons, {
                        {
                            text = _(PLUS_LABELS[id] or id),
                            callback = function()
                                UIManager:close(self.plus_dialog)
                                action.tap()
                            end,
                        },
                    })
                end
            end
            return title, buttons
        end
    end
end

userpatch.registerPatchPluginFunc("projecttitle", patchProjectTitle)
