# piconnect

[한국어](README.md)

A macOS tool that joins images in one direction. It is written in Swift and runs from a Finder Quick Action.

## Overview

piconnect takes two or more images and joins them into a single image, either horizontally or vertically.

- Horizontal joins scale every image up to the height of the tallest image.
- Vertical joins scale every image up to the width of the widest image.
- Aspect ratio is preserved. An image that is already the target size is left as it is.
- Photo orientation (EXIF) is applied.
- The result is a PNG saved next to the first image. The file is named `piconnect-h.png` or `piconnect-v.png`. If that name exists, a number is appended.
- Finder then reveals the saved file.

The direction comes from the Quick Action you choose. Running it does not open a dialog.

## Build

Requires macOS 14 or later and Swift (Xcode or the Command Line Tools).

```bash
cd /Users/jasontreks/Projects/piconnect
swift build -c release
./scripts/install.sh
```

`install.sh` copies the release build to the path below and ad-hoc signs it.

```text
$HOME/Library/Application Support/QuickTools/piconnect
```

You can also run it from the terminal.

```bash
piconnect --horizontal photo1.jpg photo2.jpg
piconnect --vertical photo1.jpg photo2.jpg
```

## Add a Quick Action

Add the Finder menu with a script. You do not need to open Automator. `--language` chooses the language of the Quick Action menu.

Korean menu items, `가로로 이어붙이기` and `세로로 이어붙이기`:

```bash
./scripts/add-quick-action.sh --language ko
```

English menu items, `Join Horizontally` and `Join Vertically`:

```bash
./scripts/add-quick-action.sh --language en
```

The only accepted values are `ko` and `en`. Running the script again with the other language removes the previous menu and leaves only the selected language.

Each item runs the installed `piconnect` binary with `--horizontal` or `--vertical`. Choosing the menu joins the selected images immediately.

### Use it

1. In Finder, select two or more images.
2. Right-click, open **Quick Actions**, and choose the menu item.
3. The PNG is saved in the same folder, and Finder selects it.

If the menu is missing, relaunch Finder, then select the images and use right-click → **Quick Actions** → **Customize** to turn the item on.
