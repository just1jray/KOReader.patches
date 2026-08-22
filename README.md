# KOReader.patches

Personal [KOReader](https://github.com/koreader/koreader) user patches. The titlebar patch is for stock [Project: Title](https://github.com/joshuacant/ProjectTitle) 3.8+.

Do not install these on top of a Project: Title fork. Use an upstream plugin release and keep customization here.

## 2-pt-titlebar.lua

Remaps the Project: Title titlebar and adds plugin rows to the plus menu. Actions prefer [Dispatcher](https://koreader.rocks/doc/modules/dispatcher.html) (the same hook as gestures). If that action is not registered, the row can fall back to a FileManager plugin method.

| Slot | Tap | Hold | Icon |
|------|-----|------|------|
| left1 | Folder up | Root / locked home | `go_up` |
| left2 | History | Collections | `history` |
| left3 | Rakuyomi | — | `tab_manga` |
| center | Home | — | `knight` (forced, custom center icon) |
| right3 | Favorites | — | `favorites` |
| right2 | Last document | — | `last_document` |
| right1 | Plus menu (stock) | — | `plus` / `check` |

Plus menu extras: Anna’s Archive, AppStore, Z-Library.

### Install

1. Install stock Project: Title into `koreader/plugins/projecttitle.koplugin`.
2. Copy `2-pt-titlebar.lua` to `koreader/patches/2-pt-titlebar.lua`.
3. Copy each file in `icons/` to `koreader/icons/`. Skip any name that already exists.
4. Restart KOReader.

### Add or change a plugin

Edit `ACTIONS` at the top of `2-pt-titlebar.lua`. A row needs a Dispatcher action name and/or FileManager fallback:

```lua
news = {
    icon = "tab_news",
    label = "News",
    dispatch = "the_dispatcher_action_name",
    keys = { "newsdownloader" },
    methods = { "onShowNews" },
},
```

Then point a slot or plus-menu entry at that id (`left3 = { tap = "news" }` or `PLUS_MENU = { "news" }`) and restart.

Dispatcher names come from the plugin’s `Dispatcher:registerAction("name", …)` call, or from stock KOReader (`history`, `favorites`, `folder_up`, `opds_show_catalog`, `exit`, …).

## Style tweaks

`styletweaks/` holds KOReader *user style tweaks* — plain `.css` files that show up under
**Typeset (2nd icon) → Style tweaks → User style tweaks**. The filename becomes the menu
title (underscores become spaces); subdirectories become submenus.

| File | What it does |
|------|--------------|
| `Dyslexia_reading.css` | One toggle for dyslexia-friendly typography: forces the reader font over publisher `font-family`, left-aligns text, disables hyphenation, sets `line-height: 1.4`, and swaps first-line indents for paragraph spacing. |

### Install

Copy each file in `styletweaks/` to `koreader/styletweaks/`, then restart KOReader (the
tweak menu is built at startup). Tap a tweak to enable it for the current book;
long-press to make it the default for all books (shown with ★).

Note: `Dyslexia_reading.css` sets `line-height`, which overrides the Line spacing slider
in the bottom config bar. It also overlaps the built-in tweaks *Ignore publisher font
families* and *Left align most text* — if you enable this file, those become redundant.
