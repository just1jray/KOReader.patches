# KOReader.patches

Personal [KOReader](https://github.com/koreader/koreader) user patches. The titlebar patch is for stock [Project: Title](https://github.com/joshuacant/ProjectTitle) 3.8+.

Do not install these on top of a Project: Title fork. Use an upstream plugin release and keep customization here.

## 2-pt-titlebar.lua

Remaps the Project: Title titlebar and adds plugin rows to the plus menu. Layout matches this Kindle’s saved settings.

| Slot | Tap | Hold | Icon |
|------|-----|------|------|
| left1 | Folder up | Root / locked home | `go_up` |
| left2 | History | Collections | `history` |
| left3 | Rakuyomi | OPDS | `tab_manga` |
| center | Home | Anna’s Archive | `hero` (forced) |
| right3 | Favorites | — | `favorites` |
| right2 | Last document | — | `last_document` |
| right1 | Plus menu (stock) | — | `plus` / `check` |

Plus menu extras: Anna’s Archive, AppStore, Z-Library.

### Install

1. Install stock Project: Title into `koreader/plugins/projecttitle.koplugin`.
2. Copy `2-pt-titlebar.lua` to `koreader/patches/2-pt-titlebar.lua`.
3. Copy each file in `icons/` to `koreader/icons/`. Skip any name that already exists.
4. Restart KOReader.

### Customize

Edit `SLOTS` and `PLUS_MENU` at the top of `2-pt-titlebar.lua`, then restart.
