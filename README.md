# DEAD ZONE

Pixel-art roguelite survivor shooter for **CC:Tweaked** on a max-size (8x6) Advanced Monitor wall, made for an ATM10 server.

## Install / update (in-game)

```
wget run https://raw.githubusercontent.com/TheWhiteRabbit78/DeadZone/main/install.lua
```

Re-run the same command to update.

## Current build: speed test

Run `speedtest`, keep the computer screen open (it's the controller).

| Key | Action |
| --- | --- |
| WASD | move |
| Space | shoot |
| E / Q | +10 / -10 mobs |
| F | 20 / 10 FPS cap |
| X | quit |

## Layout

- `dz/palette.lua` - the 16 custom colours
- `dz/gfx.lua` - 2x3 sub-pixel renderer (teletext chars, 2 colours per cell)
- `dz/sprites.lua` - all sprites as text art, one letter per pixel
- `speedtest.lua` - renderer stress test
- `install.lua` - in-game installer
