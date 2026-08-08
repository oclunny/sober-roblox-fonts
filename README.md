# Sober Roblox Font Override

Replace Roblox's in-game fonts with a custom `.ttf`, `.otf`, or `.ttc` font when using [Sober](https://sober.vinegarhq.org/) on Linux.

This works by creating an asset overlay instead of modifying the Roblox APK directly.

## Features

- Replace Roblox font families with your own font
- Works with `.ttf`, `.otf`, and `.ttc` fonts
- Finds fonts anywhere in `~/Downloads`, including subfolders
- Handles font-family JSON mappings
- Keeps Roblox emoji fonts untouched
- Offers to back up your current fonts before changing anything, and to restore that backup later
- Checks for required tools on first run and offers to install anything missing for you
- Easy to change to another font later
- No APK repacking required

## Requirements

- Linux
- [Sober](https://sober.vinegarhq.org/), installed and launched at least once
- `unzip`
- `python3`
- `sed`
- A `.ttf`, `.otf`, or `.ttc` font you are allowed to use

You don't need to install these yourself see [Dependency Check](#dependency-check) below. `find` is also used, but it's a core system tool that's virtually always already present.

> **Important:** Make sure your font contains numbers (`0–9`) and the symbols you need. Some decorative fonts may not contain every glyph.

## How It Works

Roblox stores its font families inside the APK under:

```text
assets/content/fonts/families/
```

Each family is a small JSON file that points to an `assetId` for the font file it uses. Rather than editing the APK itself, this script:

1. Extracts a fresh copy of those family JSON files from `base.apk` into Sober's asset overlay folder.
2. Copies your chosen font into the overlay, alongside the extracted families.
3. Rewrites the `assetId` in every **non-emoji** family JSON to point at your font file instead.
4. Leaves any family with `emoji` or `twemoji` in its filename completely untouched, so Roblox's emoji rendering keeps working normally.

Because Sober reads the asset overlay on top of the real APK, none of this touches the original Roblox files it can be undone at any time by clearing the overlay or restoring a backup.

## Usage

Clone the repo and run the script:

```bash
git clone https://github.com/oclunny/sober-roblox-fonts.git
cd sober-roblox-fonts
chmod +x change-font-byclunny.sh
./change-font-byclunny.sh
```

### Dependency Check

On startup, the script checks for `unzip`, `python3`, `sed`, and `find`. If everything's already installed, it just confirms that and moves on. If anything's missing, it will:

- List what's missing
- Ask **"Install the missing packages now? [Y/n]"**
- If you say yes, it detects your package manager (`apt`, `dnf`, `pacman`, `zypper`, or `apk`) and installs the right packages for your distro, using `sudo` if needed
- If you say no, it skips installation and continues straight on to the font-changing steps (a later step may fail and tell you which tool it needed)

### Choosing a Font

Put your `.ttf`, `.otf`, or `.ttc` file anywhere inside `~/Downloads` including subfolders then run the script and choose option `[1]`. It will list every font it finds, with its path relative to `~/Downloads` so files with the same name in different folders are easy to tell apart. Pick a number, confirm, and it does the rest.

You'll be asked if you want to back up your current fonts first recommended, especially the first time.

### Restoring a Backup

Run the script again and choose option `[2]` to see a list of previous backups (newest first) and restore one.

### Cleaning Up

Once you're done, the script offers to delete the cloned repo folder for you, since it's no longer needed after the font has been installed. This is optional say no to keep it around in case you want to change fonts again later.

## Notes

- Some Roblox experiences load or download their own fonts, so those may not follow the replacement.
- The font file doesn't need to stay in `~/Downloads` after installation it's already been copied into the Sober overlay by that point.

---

Created with ❤️ by clunny
