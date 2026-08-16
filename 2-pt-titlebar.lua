--[[
 Project: Title user patch — titlebar slots + plus-menu plugin rows.

 Requires stock Project: Title 3.8+.

 Install:
   1. Copy this file to koreader/patches/2-pt-titlebar.lua
   2. Copy icons/*.svg to koreader/icons/ (skip names that already exist)
   3. Restart KOReader

 Edit SLOTS, PLUS_MENU, and ACTIONS below, then restart.
 right1 (plus / select-mode check) is not configurable.

 Plugin rows prefer Dispatcher (same hook as gestures). If that action is
 not registered, the optional keys/methods fallback is used.
--]]

local userpatch = require("userpatch")
local Dispatcher = require("dispatcher")
local FileManager = require("apps/filemanager/filemanager")
local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local _ = require("gettext")

-- =========================== CONFIG ===========================
-- Point a slot at any ACTIONS id. Add a new plugin by adding an ACTIONS row
-- with dispatch = "the_dispatcher_action_name" (from that plugin's
-- Dispatcher:registerAction) and/or keys + methods as a fallback.

local SLOTS = {
    left1  = { tap = "go_up",          hold = "go_root" },
    left2  = { tap = "history",        hold = "collections" },
    left3  = { tap = "manga",          hold = "none" },
    center = { tap = "home",           hold = "none", force_icon = "knight" },
    right3 = { tap = "favorites",      hold = "none" },
    right2 = { tap = "last_document",  hold = "none" },
}

local PLUS_MENU = { "annas", "appstore", "zlib" }

local ACTIONS = {
    home = {
        icon = "home",
        dispatch = "filemanager",
    },
    favorites = {
        icon = "favorites",
        dispatch = "favorites",
    },
    folder_shortcuts = {
        icon = "favorites",
        dispatch = "folder_shortcuts",
    },
    history = {
        icon = "history",
        dispatch = "history",
    },
    last_document = {
        icon = "last_document",
        dispatch = "open_previous_document",
    },
    go_up = {
        icon = "go_up",
        dispatch = "folder_up",
    },
    go_root = {
        icon = "go_root",
        -- No stock Dispatcher action; FileManager fallback only.
        tap = function()
            local fm = FileManager.instance
            if not fm or not fm.file_chooser then return end
            if G_reader_settings:isTrue("lock_home_folder") then
                local home_dir = G_reader_settings:readSetting("home_dir")
                if home_dir then fm.file_chooser:changeToPath(home_dir) end
            else
                fm.file_chooser:changeToPath("/")
            end
        end,
    },
    collections = {
        icon = "tab_collections",
        dispatch = "collections",
    },
    exit = {
        icon = "tab_exit",
        dispatch = "exit",
    },
    manga = {
        icon = "tab_manga",
        label = "Rakuyomi",
        -- Registered in newer Rakuyomi; older builds have no Dispatcher action.
        dispatch = "rakuyomi_open_library",
        keys = { "rakuyomi" },
        methods = { "openLibraryView" },
    },
    annas = {
        icon = "tab_books",
        label = "Anna's Archive",
        dispatch = "annas_search",
        keys = { "annas_archive", "annas-archive", "annasarchive", "Anna's Archive", "annas" },
        methods = { "showMultiSearchDialog", "showSearchDialog", "onAnnasSearch", "onZlibrarySearch" },
    },
    zlib = {
        icon = "tab_news",
        label = "Z-Library",
        dispatch = "zlibrary_search",
        keys = { "Z-library", "Z-Library", "z-library", "zlibrary" },
        methods = { "showMultiSearchDialog", "onZlibrarySearch" },
    },
    appstore = {
        icon = "tab_continue",
        label = "AppStore",
        dispatch = "AppStore_open",
        keys = { "appstore", "AppStore" },
        methods = { "showBrowser" },
    },
    opds = {
        icon = "tab_history",
        label = "OPDS catalog",
        dispatch = "opds_show_catalog",
        keys = { "opds" },
        methods = { "onShowOPDSCatalog" },
    },
    none = {},
}
-- ========================= END CONFIG =========================

local SLOT_ORDER = { "left1", "left2", "left3", "center", "right3", "right2" }

local function info(text)
    UIManager:show(InfoMessage:new { text = text })
end

local function isRegistered(name)
    if not name then return false end
    return Dispatcher:getNameFromItem(name, {}) ~= _("Unknown item")
end

local function runDispatch(name)
    if not isRegistered(name) then return false end
    Dispatcher:execute({ [name] = true })
    return true
end

local function runFallback(action)
    if type(action.tap) == "function" then
        action.tap()
        return true
    end
    local fm = FileManager.instance
    if not fm then return false end
    local plugin
    for _, key in ipairs(action.keys or {}) do
        if fm[key] then
            plugin = fm[key]
            break
        end
    end
    if not plugin then return false end
    for _, method in ipairs(action.methods or {}) do
        if type(plugin[method]) == "function" then
            plugin[method](plugin)
            return true
        end
    end
    return false
end

local function runAction(action)
    if not action then return end
    if runDispatch(action.dispatch) then return end
    if runFallback(action) then return end
    if action.label or action.dispatch or action.keys then
        info(_((action.label or "Plugin") .. " not found."))
    end
end

local function callbackFor(action)
    if not action or not (action.dispatch or action.keys or action.tap) then
        return false
    end
    return function()
        runAction(action)
    end
end

local function applySlots(titlebar)
    for _, slot in ipairs(SLOT_ORDER) do
        local cfg = SLOTS[slot]
        if cfg then
            local tap_action = ACTIONS[cfg.tap] or ACTIONS.none
            local hold_action = ACTIONS[cfg.hold] or ACTIONS.none
            local icon = tap_action.icon or hold_action.icon
            if slot == "center" and (cfg.force_icon or not icon) then
                icon = cfg.force_icon or "hero"
            end
            if icon then
                titlebar[slot .. "_icon"] = icon
            elseif cfg.tap == "none" and cfg.hold == "none" then
                titlebar[slot .. "_icon"] = nil
            end
            titlebar[slot .. "_icon_tap_callback"] = callbackFor(tap_action)
            titlebar[slot .. "_icon_hold_callback"] = callbackFor(hold_action)
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
            for _i, id in ipairs(PLUS_MENU) do
                local action = ACTIONS[id]
                if action and (action.dispatch or action.keys or action.tap) then
                    if not extras_added then
                        table.insert(buttons, {})
                        extras_added = true
                    end
                    table.insert(buttons, {
                        {
                            text = _(action.label or id),
                            callback = function()
                                UIManager:close(self.plus_dialog)
                                runAction(action)
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
