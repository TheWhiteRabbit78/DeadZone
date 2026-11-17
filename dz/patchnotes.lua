-- DEAD ZONE version + patch notes (newest first). Shown from the title screen (V).

local N = {}

N.VERSION = "v2.40"

N.LIST = {
  { "v2.40", "Smarter offers + patch notes", {
    "Combo items only show up when you own something they work with",
    "  (Conductor, Permafrost, Pyromaniac, Focus Crystal, Shrapnel, Napalm, ...)",
    "Cards show what a combo item works with",
    "Outposts appear from minute 5, are rarer and always far apart",
    "Survivors show up from minute 3",
    "Version number and this patch notes screen on the title",
  } },
  { "v2.30", "Numbers you can read", {
    "HP is shown on a 100 scale (base 100, Thick Skin +30)",
    "Glass Cannon / Juggernaut change the max HP you have when you pick them;",
    "  HP you gain later counts fully, so pick order matters",
    "Fire rate past the cap and shots over the bullet limit turn into damage",
    "Floating damage numbers (H to toggle), crits in yellow",
    "DPS meter and current Zombie HP in the top bar",
    "HP bars on elites and nests",
    "Damage by source on the pause and death screens",
  } },
  { "v2.20", "Friends and water", {
    "Lakes with shorelines, reeds and lily pads - bullets fly over water",
    "Outposts: soldiers + machine-gun nest fight the horde",
    "Overrun outposts turn into infested nests that spawn mobs",
    "Destroy nests for XP, a heart and a chance at a chest",
    "Rescue trapped survivors - up to 2 followers fight with you",
    "Desktop version (CraftOS-PC) runs the same code as the server",
  } },
  { "v2.10", "The horde fights back", {
    "Mob HP compounds after minute 4, mob damage +15% per minute",
    "Mob resistance grows after minute 3 (up to 70%)",
    "Elite mobs from minute 5, swarms every 2 minutes from minute 6",
    "Endless shard upgrades once every item is maxed",
    "Corpse Bomb / Bomb Imp blasts no longer scale with mob HP",
    "Fixed title screen freezing with a Player Detector attached",
    "Crashes are saved to crash.log",
  } },
  { "v2.00", "Builds, skill tree, prestige", {
    "Gun damage and area damage are separate stats",
    "Explosion, tank and mage item lines + 4 new evolutions",
    "Spells: Fire Ring, Meteor, Frost Nova, Thunderstorm, Arcane Orbs",
    "Burn, freeze and shock status effects",
    "Banish (B) and 4-card picks",
    "Player accounts via Player Detector, souls, 333-level skill tree",
    "Prestige up to 10x, leaderboard on the title screen",
  } },
  { "v1.00", "Pixel art", {
    "Rebuilt on a pixel engine: real sprites instead of letters",
    "Smooth movement, open world with trees and rocks",
    "Zombies, Ghouls, Brutes, Skeleton archers, Bomb Imps, the Grave King",
    "4 weapons, 35 items, rarities, trade-off multipliers, evolutions",
  } },
}

return N
