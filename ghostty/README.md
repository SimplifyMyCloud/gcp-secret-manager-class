# WOPR green-phosphor CRT profile for Ghostty

Turns [Ghostty](https://ghostty.org) into a 1983 green-screen terminal for the
WarGames demo: monochrome phosphor-green palette, a blocky mainframe font, and a
subtle CRT shader (scanlines + glow + curvature).

Files:
- `config` — the Ghostty profile
- `wopr-crt.glsl` — the CRT shader (referenced by `config`)

## Install (macOS)

```bash
# 1) A blocky, old-school font (pick one; 3270 is the easiest)
brew install --cask font-3270-nerd-font
#   For extra DOS authenticity also add "Px437 IBM VGA8" from int10h.org's
#   Ultimate Oldschool PC Font Pack (drag the .ttf into Font Book).

# 2) Install the profile + shader (backs up any existing config first)
mkdir -p ~/.config/ghostty
[ -f ~/.config/ghostty/config ] && cp ~/.config/ghostty/config ~/.config/ghostty/config.bak
cp ghostty/config ghostty/wopr-crt.glsl ~/.config/ghostty/

# 3) Reload: fully quit Ghostty (Cmd+Q) and reopen — or press the
#    reload-config binding (default: Cmd+Shift+,)
```

Prefer to keep this repo as the source of truth? Symlink instead of copy:

```bash
ln -sf "$PWD/ghostty/config"       ~/.config/ghostty/config
ln -sf "$PWD/ghostty/wopr-crt.glsl" ~/.config/ghostty/wopr-crt.glsl
```

> `custom-shader = wopr-crt.glsl` is resolved next to the config file, so both
> files must live in the same directory (`~/.config/ghostty/`).

## Verify the font name

Nerd Font family names vary slightly. Confirm what Ghostty sees and edit the
first `font-family` line in `config` to match:

```bash
ghostty +list-fonts | grep -iE '3270|VGA'
```

(If the `ghostty` CLI isn't on your PATH, it's inside the app bundle:
`/Applications/Ghostty.app/Contents/MacOS/ghostty +list-fonts`.)

## Tuning

| Want | Do |
|---|---|
| **Text clipping at corners** (projector) | lower `CURVATURE_STRENGTH` in `wopr-crt.glsl`, or comment out `custom-shader` in `config` |
| **Stronger/weaker scanlines** | edit `SCANLINE_STRENGTH` (0.0–0.3) |
| **No CRT at all, just green** | comment out the `custom-shader` line |
| **Blockier text** | raise `font-size`, keep `font-thicken = true`, try `adjust-cell-height = 12%` |
| **Title bar back** | set `macos-titlebar-style = native` |

## Amber monitor instead of green?

Swap the color block in `config` for amber phosphor:

```
background = #160d00
foreground = #ffb000
cursor-color = #ffb000
cursor-text  = #160d00
selection-background = #ffb000
selection-foreground = #160d00
palette = 0=#160d00
palette = 1=#cc7000
palette = 2=#ffb000
palette = 3=#ffc233
palette = 7=#ffd980
palette = 15=#fff0cc
```

And in `wopr-crt.glsl`, change `col.g *= 1.03;` to `col.r *= 1.03;`.

## Best paired with

```bash
TYPE_SPEED=0.02 ./demos/present.sh   # WOPR types its commands on the green CRT
```
