#!/usr/bin/env bash
set -euo pipefail

# Roblox Font Changer for Sober
# Linux / Sober (VinegarHQ)
#
# What it does:
# 1. Looks for font files anywhere in ~/Downloads (including subfolders).
# 2. Lets you choose a font interactively.
# 3. Backs up the existing Sober asset overlay (optional).
# 4. Extracts Roblox's font-family JSON files from base.apk.
# 5. Replaces every non-emoji font family with your chosen font.
# 6. Leaves emoji-related fonts/families alone.
# 7. Offers to delete this cloned repo folder once you're done.
#
# Run from a terminal, right after cloning oclunny/sober-roblox-fonts:
#   chmod +x change-font-byclunny.sh
#   ./change-font-byclunny.sh

SOBER="$HOME/.var/app/org.vinegarhq.Sober/data/sober"
OVERLAY="$SOBER/asset_overlay"
APK="$SOBER/packages/x86_64/com.roblox.client/base.apk"
DOWNLOADS="$HOME/Downloads"

# Folder this script lives in (i.e. the cloned repo), used later for the
# optional cleanup step. Resolved this way so it still works no matter
# where the repo was cloned to.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# Basic dependency check, with an offer to auto-install anything missing
# (kept simple for beginners running this on a fresh PC for the first time)
# ---------------------------------------------------------------------------

# Tools this script relies on, and the package name that provides each one
# per package manager. `find` is part of core/findutils and is essentially
# always present, so it isn't offered for auto-install below.
declare -A PKG_APT=( [unzip]="unzip" [python3]="python3" [sed]="sed" )
declare -A PKG_DNF=( [unzip]="unzip" [python3]="python3" [sed]="sed" )
declare -A PKG_PACMAN=( [unzip]="unzip" [python3]="python" [sed]="sed" )
declare -A PKG_ZYPPER=( [unzip]="unzip" [python3]="python3" [sed]="sed" )
declare -A PKG_APK=( [unzip]="unzip" [python3]="python3" [sed]="sed" )

MISSING=()
command -v unzip   >/dev/null 2>&1 || MISSING+=("unzip")
command -v python3 >/dev/null 2>&1 || MISSING+=("python3")
command -v sed     >/dev/null 2>&1 || MISSING+=("sed")
command -v find    >/dev/null 2>&1 || MISSING+=("find")

echo "Checking required tools (unzip, python3, sed, find)..."

if [[ ${#MISSING[@]} -eq 0 ]]; then
    echo "All required tools are already installed. Continuing..."
    echo
fi

if [[ ${#MISSING[@]} -gt 0 ]]; then
    echo "This script needs a few command-line tools that aren't installed:"
    for tool in "${MISSING[@]}"; do
        echo "  - $tool"
    done
    echo
    read -r -p "Install the missing packages now? [Y/n]: " INSTALL_DEPS

    if [[ "$INSTALL_DEPS" =~ ^[Nn]$ ]]; then
        echo
        echo "Skipping package installation. Continuing on to the font script..."
        echo "(If a missing tool is actually needed, a step further down will fail"
        echo " and tell you which one.)"
    else
        # Figure out which package manager is available and build the list
        # of package names to install for it.
        SUDO=""
        if [[ "$(id -u)" -ne 0 ]]; then
            if command -v sudo >/dev/null 2>&1; then
                SUDO="sudo"
            else
                echo
                echo "ERROR: Not running as root and 'sudo' isn't available,"
                echo "so packages can't be installed automatically."
                echo "Please install the tools listed above manually, then run"
                echo "this script again."
                exit 1
            fi
        fi

        INSTALL_CMD=()
        if command -v apt-get >/dev/null 2>&1; then
            PKGS=(); for t in "${MISSING[@]}"; do [[ -n "${PKG_APT[$t]:-}" ]] && PKGS+=("${PKG_APT[$t]}"); done
            INSTALL_CMD=($SUDO apt-get update -y "&&" $SUDO apt-get install -y "${PKGS[@]}")
            echo
            echo "Detected apt (Debian/Ubuntu). Running:"
            echo "  $SUDO apt-get update -y && $SUDO apt-get install -y ${PKGS[*]}"
            $SUDO apt-get update -y
            $SUDO apt-get install -y "${PKGS[@]}"
        elif command -v dnf >/dev/null 2>&1; then
            PKGS=(); for t in "${MISSING[@]}"; do [[ -n "${PKG_DNF[$t]:-}" ]] && PKGS+=("${PKG_DNF[$t]}"); done
            echo
            echo "Detected dnf (Fedora). Running:"
            echo "  $SUDO dnf install -y ${PKGS[*]}"
            $SUDO dnf install -y "${PKGS[@]}"
        elif command -v pacman >/dev/null 2>&1; then
            PKGS=(); for t in "${MISSING[@]}"; do [[ -n "${PKG_PACMAN[$t]:-}" ]] && PKGS+=("${PKG_PACMAN[$t]}"); done
            echo
            echo "Detected pacman (Arch). Running:"
            echo "  $SUDO pacman -S --noconfirm ${PKGS[*]}"
            $SUDO pacman -S --noconfirm "${PKGS[@]}"
        elif command -v zypper >/dev/null 2>&1; then
            PKGS=(); for t in "${MISSING[@]}"; do [[ -n "${PKG_ZYPPER[$t]:-}" ]] && PKGS+=("${PKG_ZYPPER[$t]}"); done
            echo
            echo "Detected zypper (openSUSE). Running:"
            echo "  $SUDO zypper install -y ${PKGS[*]}"
            $SUDO zypper install -y "${PKGS[@]}"
        elif command -v apk >/dev/null 2>&1; then
            PKGS=(); for t in "${MISSING[@]}"; do [[ -n "${PKG_APK[$t]:-}" ]] && PKGS+=("${PKG_APK[$t]}"); done
            echo
            echo "Detected apk (Alpine). Running:"
            echo "  $SUDO apk add ${PKGS[*]}"
            $SUDO apk add "${PKGS[@]}"
        else
            echo
            echo "ERROR: Couldn't detect a supported package manager"
            echo "(apt, dnf, pacman, zypper, or apk)."
            echo
            echo "Please install these manually, then run this script again:"
            printf '  %s\n' "${MISSING[@]}"
            exit 1
        fi

        # Re-check after attempting install.
        STILL_MISSING=()
        command -v unzip   >/dev/null 2>&1 || STILL_MISSING+=("unzip")
        command -v python3 >/dev/null 2>&1 || STILL_MISSING+=("python3")
        command -v sed     >/dev/null 2>&1 || STILL_MISSING+=("sed")

        if [[ ${#STILL_MISSING[@]} -gt 0 ]]; then
            echo
            echo "WARNING: Still missing after install attempt:"
            printf '  - %s\n' "${STILL_MISSING[@]}"
            echo "You may need to install these by hand before continuing."
        else
            echo
            echo "All required packages are installed."
        fi
    fi
fi

if [[ ! -f "$APK" ]]; then
    echo "ERROR: Roblox base.apk was not found:"
    echo "  $APK"
    echo
    echo "Make sure Sober/Roblox has been installed and launched at least once."
    exit 1
fi

# ---------------------------------------------------------------------------
# Helper: offer to delete this cloned repo folder
# ---------------------------------------------------------------------------

offer_repo_cleanup() {
    echo
    echo "This script lives in the cloned repo folder:"
    echo "  $SCRIPT_DIR"
    echo

    if [[ ! -d "$SCRIPT_DIR/.git" ]]; then
        echo "(This doesn't look like a git repo folder, so cleanup is skipped"
        echo " automatically. You can still delete it manually if you want.)"
        return
    fi

    read -r -p "Delete this cloned repo folder now that you're done? [y/N]: " DELETE_REPO
    if [[ "$DELETE_REPO" =~ ^[Yy]$ ]]; then
        echo
        echo "Deleting:"
        echo "  $SCRIPT_DIR"
        cd "$HOME"
        rm -rf "$SCRIPT_DIR"
        echo "Repo folder deleted. All done!"
    else
        echo "Keeping the repo folder. You can delete it manually any time,"
        echo "or re-run this script later to change fonts again."
    fi
}

echo
echo "=========================================="
echo "      Sober Roblox Font Changer"
echo "=========================================="
echo
echo "What would you like to do?"
echo
echo "  [1] Install/change Roblox fonts"
echo "  [2] Restore a previous font backup"
echo
read -r -p "Choose an option [1-2]: " ACTION

if [[ "$ACTION" == "2" ]]; then
    echo
    echo "Available backups:"
    echo

    mapfile -t BACKUPS < <(
        find "$SOBER" -maxdepth 1 -mindepth 1 -type d -name 'font-backup-*' -printf '%f\n' | sort -r
    )

    if [[ ${#BACKUPS[@]} -eq 0 ]]; then
        echo "No font backups were found."
        exit 1
    fi

    for i in "${!BACKUPS[@]}"; do
        printf "  [%d] %s\n" "$((i + 1))" "${BACKUPS[$i]}"
    done

    echo
    read -r -p "Which backup do you want to restore? Enter its number: " RESTORE_CHOICE

    if ! [[ "$RESTORE_CHOICE" =~ ^[0-9]+$ ]] ||
       (( RESTORE_CHOICE < 1 || RESTORE_CHOICE > ${#BACKUPS[@]} )); then
        echo "Invalid choice."
        exit 1
    fi

    BACKUP="$SOBER/${BACKUPS[$((RESTORE_CHOICE - 1))]}"

    if pgrep -x sober >/dev/null 2>&1; then
        echo
        echo "Sober is running. Closing it before restoring..."
        pkill -x sober || true
        sleep 2
    fi

    echo
    echo "Restoring:"
    echo "  $BACKUP"
    echo
    echo "to:"
    echo "  $OVERLAY"

    rm -rf "$OVERLAY"
    mkdir -p "$OVERLAY"
    cp -a "$BACKUP/." "$OVERLAY/"

    echo
    echo "Restore complete!"
    echo "Start Sober normally to use the restored fonts."

    offer_repo_cleanup

    echo
    echo "Created with ❤️ by clunny"
    echo
    exit 0
fi

if [[ "$ACTION" != "1" ]]; then
    echo "Invalid choice."
    exit 1
fi

echo
echo "Font files can be anywhere inside:"
echo "  $DOWNLOADS"
echo "(including subfolders, e.g. $DOWNLOADS/MyFont/)"
echo

if [[ ! -d "$DOWNLOADS" ]]; then
    echo "ERROR: Downloads folder was not found:"
    echo "  $DOWNLOADS"
    exit 1
fi

# Find usable font files anywhere in Downloads, including subfolders.
mapfile -d '' FONTS < <(
    find "$DOWNLOADS" -type f \
        \( -iname '*.ttf' -o -iname '*.otf' -o -iname '*.ttc' \) \
        -print0 | sort -z
)

if [[ ${#FONTS[@]} -eq 0 ]]; then
    echo "No .ttf, .otf, or .ttc fonts were found in Downloads or its subfolders."
    echo
    echo "Put your font file somewhere inside ~/Downloads and run this again."
    exit 1
fi

echo "Found these fonts:"
echo

for i in "${!FONTS[@]}"; do
    # Show the path relative to Downloads so fonts in subfolders are
    # easy to tell apart from ones with the same filename.
    REL="${FONTS[$i]#"$DOWNLOADS"/}"
    printf "  [%d] %s\n" "$((i + 1))" "$REL"
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
    FAMILY="$(fc-scan --format='%{family}\n' "$FONT" 2>/dev/null | head -n 1 || true)"
    STYLE="$(fc-scan --format='%{style}\n' "$FONT" 2>/dev/null | head -n 1 || true)"
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

# Optionally make a timestamped backup before changing anything.
echo
read -r -p "Do you want to create a backup before installing the new font? [Y/n]: " DO_BACKUP

if [[ ! "$DO_BACKUP" =~ ^[Nn]$ ]]; then
    BACKUP="$SOBER/font-backup-$(date +%Y%m%d-%H%M%S)"

    if [[ -d "$OVERLAY" ]] && [[ -n "$(find "$OVERLAY" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]; then
        echo
        echo "Backing up current font overlay to:"
        echo "  $BACKUP"
        mkdir -p "$BACKUP"
        cp -a "$OVERLAY/." "$BACKUP/"
        echo "Backup complete."
    else
        echo
        echo "No existing font overlay to back up. Skipping backup."
    fi
else
    echo
    echo "Backup skipped."
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
echo "the backup shown above (or re-run this script and choose option [2])."
echo
echo "IMPORTANT:"
echo "- The font file no longer needs to stay in ~/Downloads after this,"
echo "  since it has already been copied into the Sober overlay."
echo "- Emoji fonts are intentionally not replaced."
echo "- Some Roblox experiences can load/download their own fonts,"
echo "  so those may not follow the replacement."

offer_repo_cleanup

echo
echo "Created with ❤️ by clunny"
echo
