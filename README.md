# DEAD ZONE

Pixel-art roguelite survivor shooter for **CC:Tweaked** on a max-size (8x6) Advanced Monitor wall, made for an ATM10 server.

## Install / update (in-game)

```
wget run https://raw.githubusercontent.com/TheWhiteRabbit78/DeadZone/main/install.lua
```

Then run `deadzone`. Re-run the install command to update (your save is kept).
Put a **Speaker** next to the computer for sound.

## Controls

Keep the computer screen open while playing - it's the controller.

| Key | Action |
| --- | --- |
| WASD | move (8 directions) |
| Space | shoot where you face (hold) |
| Arrows | aim + shoot |
| 1 2 3 4 | switch weapon |
| 1 2 3 | pick an item on level up |
| R | reroll items (3 per run) |
| P | pause + see your build |

## The game

- Endless field, mobs get tougher every minute: Zombies, Ghouls (0:40), Brutes (1:40), Skeleton archers (2:30), Bomb Imps (3:30)
- A horde every minute, the Grave King boss every 3 minutes - he drops a chest with an epic+ item
- Level up -> pick 1 of 3 items. Common / Rare / Epic / Legendary
- Builds: small safe bonuses add up, big multipliers (x) stack exponentially but come with a drawback
- Evolutions: Saw Storm, Nuke Launcher, Plague Heart - max the right items to unlock them

## Layout

- `deadzone.lua` - the game
- `dz/items.lua` - all items, rarities and stat maths (easy to tweak)
- `dz/sprites.lua` - all sprites as text art, one letter per pixel
- `dz/world.lua` - ground, trees, rocks, collision
- `dz/gfx.lua` - 2x3 sub-pixel renderer
- `dz/palette.lua` - the 16 colours
- `speedtest.lua` - renderer stress test
