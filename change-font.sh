#!/usr/bin/env bash
set -euo pipefail

# Roblox Font Changer for Sober
# Linux / Sober (VinegarHQ)
#
# What it does:
# 1. Looks for font files in ~/Downloads.
# 2. Lets you choose a font interactively.
# 3. Backs up the existing Sober asset overlay.
# 4. Extracts Roblox's font-family JSON files from base.apk.
# 5. Replaces every non-emoji font family with your chosen font.
# 6. Leaves emoji-related fonts/families alone.
#
# Run from a terminal:
#   chmod +x change-font.sh
#   ./change-font.sh

SOBER="$HOME/.var/app/org.vinegarhq.Sober/data/sober"
OVERLAY="$SOBER/asset_overlay"
APK="$SOBER/packages/x86_64/com.roblox.client/base.apk"
DOWNLOADS="$HOME/Downloads"

if [[ ! -f "$APK" ]]; then
    echo "ERROR: Roblox base.apk was not found:"
    echo "  $APK"
    echo
    echo "Make sure Sober/Roblox has been installed and launched at least once."
    exit 1
fi

if ! command -v unzip >/dev/null 2>&1; then
    echo "ERROR: unzip is required."
    echo "Install it with your distro's package manager, then run this again."
    exit 1
fi

echo
echo "=========================================="
echo "      Sober Roblox Font Changer"
echo "=========================================="
echo
echo "Font files must be in:"
echo "  $DOWNLOADS"
echo

# Find usable font files directly in Downloads.
mapfile -d '' FONTS < <(
    find "$DOWNLOADS" -maxdepth 1 -type f \
        \( -iname '*.ttf' -o -iname '*.otf' -o -iname '*.ttc' \) \
        -print0 | sort -z
)

if [[ ${#FONTS[@]} -eq 0 ]]; then
    echo "No .ttf, .otf, or .ttc fonts were found in Downloads."
    echo
    echo "Put your font file directly in ~/Downloads and run this again."
    exit 1
fi

echo "Found these fonts:"
echo

for i in "${!FONTS[@]}"; do
    printf "  [%d] %s\n" "$((i + 1))" "$(basename "${FONTS[$i]}")"
done

echo
read -r -p "Which font do you want to use? Enter its number: " CHOICE

if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] ||
   (( CHOICE < 1 || CHOICE > ${#FONTS[@]} )); then
    echo "Invalid choice."
    exit 1
fi

FONT="${FONTS[$((CHOICE - 1))]}"
FONT_NAME="$(basename "$FONT")"

echo
echo "Selected font: $FONT_NAME"
echo

# Show basic font metadata if fontconfig tools are installed.
if command -v fc-scan >/dev/null 2>&1; then
    FAMILY="$(fc-scan --format='%{family}\\n' "$FONT" 2>/dev/null | head -n 1 || true)"
    STYLE="$(fc-scan --format='%{style}\\n' "$FONT" 2>/dev/null | head -n 1 || true)"
    [[ -n "$FAMILY" ]] && echo "Font family: $FAMILY"
    [[ -n "$STYLE" ]] && echo "Font style:  $STYLE"
    echo
fi

read -r -p "Continue and replace all non-emoji Roblox fonts? [y/N]: " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# Close/kill Sober if it is currently running.
if pgrep -x sober >/dev/null 2>&1; then
    echo
    echo "Sober is running. Closing it before changing the files..."
    pkill -x sober || true
    sleep 2
fi

mkdir -p "$OVERLAY/content/fonts/families" "$OVERLAY/fonts"

# Make a timestamped backup of the current overlay.
BACKUP="$SOBER/font-backup-$(date +%Y%m%d-%H%M%S)"
if [[ -d "$OVERLAY" ]] && [[ -n "$(find "$OVERLAY" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]; then
    echo "Backing up current font overlay to:"
    echo "  $BACKUP"
    mkdir -p "$BACKUP"
    cp -a "$OVERLAY/." "$BACKUP/"
fi

echo
echo "Refreshing Roblox font-family files from base.apk..."

# Restore fresh family JSON files from the APK.
rm -f "$OVERLAY/content/fonts/families/"*.json
unzip -j -q "$APK" 'assets/content/fonts/families/*.json' \
    -d "$OVERLAY/content/fonts/families"

# Copy the chosen font into both locations used by Roblox/Sober.
# Keep the original filename so the family JSON can reference it.
cp -f "$FONT" "$OVERLAY/content/fonts/$FONT_NAME"
cp -f "$FONT" "$OVERLAY/fonts/$FONT_NAME"

# Replace every local or remote assetId in every non-emoji font family.
#
# Emoji-related families are intentionally skipped. This means:
# - RobloxEmoji stays untouched.
# - TwemojiMozilla stays untouched.
# - Other families whose filename contains "emoji" stay untouched.
#
# The replacement is done with Python because it safely handles JSON text
# without requiring sed-specific escaping for filenames.
export FAMILY_DIR="$OVERLAY/content/fonts/families"
export CHOSEN_FONT="$FONT_NAME"

python3 <<'PY'
import os
import re
from pathlib import Path

family_dir = Path(os.environ["FAMILY_DIR"])
font_name = os.environ["CHOSEN_FONT"]

# Replace the value of assetId, regardless of whether it is:
# rbxasset://fonts/...
# rbxassetid://...
# or another Roblox asset reference.
asset_id = re.compile(r'("assetId"\s*:\s*")[^"]*(")')

changed = 0
skipped = 0

for path in sorted(family_dir.glob("*.json")):
    lower = path.name.lower()

    # Do not alter emoji families.
    if "emoji" in lower or "twemoji" in lower:
        skipped += 1
        continue

    text = path.read_text(encoding="utf-8")
    new_text, count = asset_id.subn(
        lambda m: f'{m.group(1)}rbxasset://fonts/{font_name}{m.group(2)}',
        text,
    )

    if count:
        path.write_text(new_text, encoding="utf-8")
        changed += 1

print(f"Changed {changed} font-family JSON files.")
print(f"Skipped {skipped} emoji-related family files.")
PY

echo
echo "Verifying..."

echo
echo "Chosen font:"
file "$OVERLAY/content/fonts/$FONT_NAME"

echo
echo "Family JSON files:"
find "$OVERLAY/content/fonts/families" -maxdepth 1 -type f -name '*.json' | wc -l

echo
echo "Checking for remaining non-emoji asset IDs:"
REMAINING="$(
    grep -RIl 'rbxassetid://\|rbxasset://fonts/' \
        "$OVERLAY/content/fonts/families" 2>/dev/null |
    while IFS= read -r file; do
        if [[ "$(basename "$file" | tr '[:upper:]' '[:lower:]')" != *emoji* ]]; then
            echo "$file"
        fi
    done
)"

if [[ -n "$REMAINING" ]]; then
    echo "Some non-emoji family files still contain asset references:"
    echo "$REMAINING"
    echo
    echo "This does not necessarily mean the font failed; inspect those files if needed."
else
    echo "All non-emoji family mappings were replaced."
fi

echo
echo "=========================================="
echo "Done!"
echo "=========================================="
echo
echo "Font: $FONT_NAME"
echo "Overlay: $OVERLAY"
echo
echo "Start Sober normally and test Roblox."
echo
echo "If you want to undo this change, remove the overlay and restore"
echo "the backup shown above."
echo
echo "IMPORTANT:"
echo "- Keep the font file in ~/Downloads when you run this script."
echo "- Emoji fonts are intentionally not replaced."
echo "- Some Roblox experiences can load/download their own fonts,"
echo "  so those may not follow the replacement."
echo
