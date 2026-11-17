# DEAD ZONE

Pixel-art roguelite survivor shooter for **CC:Tweaked** on a max-size (8x6) Advanced Monitor wall, made for an ATM10 server.

## Install / update (in-game)

```
wget run https://raw.githubusercontent.com/TheWhiteRabbit78/DeadZone/main/install.lua
```

Then run `deadzone`. Re-run the install command to update - saves are kept.

Optional blocks next to the computer:
- **Speaker** - sound
- **Player Detector** (Advanced Peripherals) - right-click it to log in; every player gets their own save, souls and skill tree

## Controls

Keep the computer screen open while playing - it's the controller.

| Key | Action |
| --- | --- |
| WASD | move (8 directions) |
| Space | shoot where you face (hold) |
| Arrows | aim + shoot |
| 1 2 3 4 | switch weapon / pick an item on level up |
| R / B | reroll / banish items |
| P | pause + see your build |
| T | skill tree (title / death screen) |
| N | type a name to log in (no Player Detector) |

## The game

- Endless field, mobs get tougher every minute: Zombies, Ghouls, Brutes, Skeleton archers, Bomb Imps
- A horde every minute, the Grave King boss every 3 minutes - he drops a chest with an epic+ item
- ~70 items in 4 rarities. Small bonuses add up; big multipliers (x) stack exponentially but have drawbacks
- Damage types: **gun** (bullets) and **area** (explosions, aura, fire, spells) - items push one or the other
- Build lines: guns, explosions (mortar, napalm, shrapnel, chain reaction), tank (armor, thorns, shield, lifesteal, revive), mage (Fire Ring, Meteor, Frost Nova, Thunderstorm, Arcane Orbs + burn / freeze / shock)
- 7 evolutions: Saw Storm, Nuke Launcher, Plague Heart, Iron Maiden, Inferno, Armageddon, Absolute Zero

## Skill tree + prestige

- Every run earns **souls**: kills / 10 + 5 per minute + 25 per boss
- 59 nodes, 333 levels in four branches (Firepower, Arcana, Fortitude, Fortune) with keystones and apex nodes - roughly 30-50 hours to max
- Max everything -> **Prestige** (up to 10x): tree resets, you keep 10% of the full tree per prestige, +25% souls, but the undead get +20% HP each time
- Leaderboard on the title screen

## Files

- `deadzone.lua` - the game
- `dz/items.lua` - all run items, rarities and stat maths
- `dz/tree.lua` - skill tree nodes, costs, prestige rules
- `dz/profile.lua` - player saves + leaderboard
- `dz/sprites.lua` - all sprites as text art, one letter per pixel
- `dz/world.lua` - ground, trees, rocks, collision
- `dz/gfx.lua` - 2x3 sub-pixel renderer
- `dz/palette.lua` - the 16 colours
- `speedtest.lua` - renderer stress test
