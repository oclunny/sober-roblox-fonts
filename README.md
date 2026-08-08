# Sober Roblox Font Override

Replace Roblox's in-game fonts with a custom `.ttf` or `.otf` font when using [Sober](https://sober.vinegarhq.org/) on Linux.

This works by creating an asset overlay instead of modifying the Roblox APK directly.

## Features

- Replace Roblox font families with your own font
- Works with `.ttf` and `.otf` fonts
- Handles font-family JSON mappings
- Keeps Roblox emoji fonts untouched
- Easy to change to another font later
- No APK repacking required

## Requirements

- Linux
- [Sober](https://sober.vinegarhq.org/)
- `unzip`
- `sed`
- A `.ttf` or `.otf` font you are allowed to use

> **Important:** Make sure your font contains numbers (`0–9`) and the symbols you need. Some decorative fonts may not contain every glyph.

## How It Works

Roblox stores its font families inside the APK under:

```text
assets/content/fonts/families/
