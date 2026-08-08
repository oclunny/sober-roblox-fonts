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


# 1. Find your font

Put the font you want to use in your Downloads folder.

Example:

```text
~/Downloads/Cherry PERSONAL USE ONLY!.ttf

Check that Linux recognizes it:

file "$HOME/Downloads/Cherry PERSONAL USE ONLY!.ttf"

You should see something like:

TrueType Font data
2. Set the Sober paths

Open a terminal and run:

set OVERLAY "$HOME/.var/app/org.vinegarhq.Sober/data/sober/asset_overlay"
set APK "$HOME/.var/app/org.vinegarhq.Sober/data/sober/packages/x86_64/com.roblox.client/base.apk"
set FONT "$HOME/Downloads/Cherry PERSONAL USE ONLY!.ttf"

Create the required directories:

mkdir -p "$OVERLAY/content/fonts/families"
3. Copy the Roblox font families

Roblox stores font-family definitions as JSON files.

Extract them from the Roblox APK:

unzip -j "$APK" 'assets/content/fonts/families/*.json' -d "$OVERLAY/content/fonts/families"

You should now see files such as:

BuilderSans.json
SourceSansPro.json
Roboto.json
Montserrat.json
...
4. Copy your custom font

Copy your font into Sober's font directory:

cp "$FONT" "$OVERLAY/fonts/Cherry.ttf"

Create the directory first if necessary:

mkdir -p "$OVERLAY/fonts"

Check it:

file "$OVERLAY/fonts/Cherry.ttf"
5. Replace the font references

Roblox's font-family JSON files tell Roblox which font file to load.

We can replace references to Roblox's local font files with our custom font.

Run:

grep -RIl 'rbxasset://fonts/' "$OVERLAY/content/fonts/families" |
while read -l file
    sed -i 's#rbxasset://fonts/[^"]*#rbxasset://fonts/Cherry.ttf#g' "$file"
end

This changes the local font references to:

rbxasset://fonts/Cherry.ttf
6. Make sure emoji fonts are untouched

Do not replace:

RobloxEmoji.ttf
TwemojiMozilla.ttf

These are used for emoji rendering.

7. Check the replacement

Run:

grep -R 'Cherry.ttf' "$OVERLAY/content/fonts/families" | head

You should see entries like:

"assetId": "rbxasset://fonts/Cherry.ttf"

You can also check how many family files reference it:

grep -RIl 'Cherry.ttf' "$OVERLAY/content/fonts/families" | wc -l
8. Start Sober

Completely close Roblox/Sober first.

Then start Sober normally.

The custom font should now be used by Roblox.

Troubleshooting
Font changed in some places but not others

Roblox can use fonts from multiple locations.

Check the APK for font files:

unzip -l "$APK" | grep -Ei '\.(ttf|otf|ttc)$'

Also check the font-family definitions:

unzip -l "$APK" | grep -Ei 'font.*json|json.*font'
Roblox says a font failed to load

Check the Sober logs:

grep -RiE 'font|Font' \
"$HOME/.var/app/org.vinegarhq.Sober/data/sober/sober_logs/" | tail -100

If you see:

Font family ... failed to load

the font file or its path may not be compatible.

The font has missing numbers or characters

Not every decorative font contains every Unicode character.

For example, some fonts may have letters but lack:

Numbers
Symbols
Punctuation
Other languages

If numbers or symbols are missing, try another font with broader character coverage.

Changing the font later

You do not need to redo everything.

Set FONT to your new font:

set FONT "$HOME/Downloads/MyNewFont.ttf"

Then copy it:

cp "$FONT" "$OVERLAY/fonts/Cherry.ttf"

Because the Roblox family files already point to:

Cherry.ttf

you can keep the same filename and simply replace the font file.

Restart Sober/Roblox.

Resetting everything

To remove the custom font overlay:

rm -rf "$OVERLAY"

Then restart Sober.

Warning: this removes the entire Sober asset overlay, including other customizations.

Credits

Made as a community guide for customizing Roblox fonts on Linux/Sober.

Use fonts according to their individual licenses.


### One important thing

Since we're putting this on GitHub, **don't put your personal username/path** like:

```text
/home/clunny/...

Use:

$HOME

like we did above. That way someone else can copy the commands directly on their own PC.

And I'd also put a big note near the top:

Font licenses: Only use fonts you have permission to use. Some fonts are personal-use-only.

That matters especially since you were using Cherry PERSONAL USE ONLY.
