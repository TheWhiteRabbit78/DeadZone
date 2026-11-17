-- DEAD ZONE items: the build system.
--
-- Every stat is computed as:   (base + flat) * (1 + pct) * mult
--   mods = { gundmg_pct = 0.12 }  -> +12% (adds up with other % bonuses)
--   mods = { aoedmg_x = 2 }       -> x2 (multiplies with everything; stacks exponentially)
--   mods = { proj = 1 }           -> flat +1
-- Lines starting with "!" are drawbacks (shown red).
--
-- Damage types:  gun  = bullets            (gundmg)
--                area = explosions, aura, fire, spells, thorns, mortar (aoedmg)
--                "dmg" multiplies everything.

local I = {}

I.RARITY = {
  common    = { name = "COMMON",    col = "W", weight = 60 },
  rare      = { name = "RARE",      col = "C", weight = 28 },
  epic      = { name = "EPIC",      col = "O", weight = 10 },
  legendary = { name = "LEGENDARY", col = "Y", weight = 2.5 },
}
I.RARITY_ORDER = { "common", "rare", "epic", "legendary" }

I.BASE = {
  -- offense
  dmg = 1, gundmg = 1, aoedmg = 1, rate = 1, proj = 0, pierce = 0, range = 1,
  crit = 0.05, critdmg = 2, area = 1, boom = 1,
  bloodpact = 0, chain = 0, split = 0, ricochet = 0, corpse = 0,
  saws = 0, sawdmg = 1, aura = 0,
  exround = 0, shrapnel = 0, napalm = 0, mortar = 0, chainreact = 0,
  -- spells
  firering = 0, fireringdmg = 1, meteor = 0, meteordmg = 1, frost = 0, frostcd = 1,
  thunder = 0, orbs = 0, cdr = 1, burn = 1, pyro = 0, permafrost = 0, conductor = 0,
  -- defense
  maxhp = 10, regen = 0, armor = 0, dodge = 0, lifesteal = 0, iframes = 1,
  thorns = 0, thornpulse = 0, shield = 0, retal = 0, bulwark = 0, revive = 0,
  -- utility
  speed = 1, magnet = 28, xp = 1, luck = 0, spawn = 1, drain = 0,
  rerolls = 3, banish = 0, choices = 3, bosschests = 1, headstart = 0, souls = 1, drops = 1,
}

I.LIST = {
  ---------------------------------------------------------------- common
  { id = "sharp",   name = "Sharpened Rounds", rarity = "common", max = 5, mods = { gundmg_pct = 0.12 }, lines = { "+12% gun damage" } },
  { id = "oil",     name = "Oiled Trigger",    rarity = "common", max = 5, mods = { rate_pct = 0.10 },   lines = { "+10% fire rate" } },
  { id = "boots",   name = "Running Boots",    rarity = "common", max = 4, mods = { speed_pct = 0.10 },  lines = { "+10% move speed" } },
  { id = "skin",    name = "Thick Skin",       rarity = "common", max = 5, mods = { maxhp = 3 },         lines = { "+3 max HP" }, heal = 3 },
  { id = "charm",   name = "Magnet Charm",     rarity = "common", max = 3, mods = { magnet_pct = 0.4 },  lines = { "+40% pickup range" } },
  { id = "scope",   name = "Scope",            rarity = "common", max = 3, mods = { range_pct = 0.2 },   lines = { "+20% range" } },
  { id = "bandage", name = "Bandages",         rarity = "common", max = 3, mods = { regen = 1 },         lines = { "+1 HP every 10s" } },
  { id = "coin",    name = "Lucky Coin",       rarity = "common", max = 4, mods = { crit = 0.05, luck = 0.5 }, lines = { "+5% crit chance", "+luck (rarer items)" } },
  { id = "notes",   name = "Study Notes",      rarity = "common", max = 3, mods = { xp_pct = 0.15 },     lines = { "+15% XP" } },
  { id = "powder",  name = "Black Powder",     rarity = "common", max = 5, mods = { aoedmg_pct = 0.12 }, lines = { "+12% area damage" } },
  { id = "padding", name = "Padded Vest",      rarity = "common", max = 4, mods = { armor = 0.5 },       lines = { "+0.5 armor" } },
  { id = "focus",   name = "Focus Crystal",    rarity = "common", max = 3, mods = { cdr_pct = -0.10 },   lines = { "Spells recharge 10% faster" } },

  ---------------------------------------------------------------- rare
  { id = "barrel",  name = "Extra Barrel",  rarity = "rare", max = 3, mods = { proj = 1, gundmg_pct = -0.10 }, lines = { "+1 projectile", "!-10% gun damage" } },
  { id = "ap",      name = "AP Rounds",     rarity = "rare", max = 3, mods = { pierce = 1 },             lines = { "Bullets pierce +1 enemy" } },
  { id = "heavy",   name = "Heavy Rounds",  rarity = "rare", max = 3, mods = { gundmg_x = 1.6, rate_x = 0.75 }, lines = { "x1.6 gun damage", "!-25% fire rate" } },
  { id = "hair",    name = "Hair Trigger",  rarity = "rare", max = 3, mods = { rate_x = 1.8, gundmg_x = 0.7 },  lines = { "x1.8 fire rate", "!-30% gun damage" } },
  { id = "hollow",  name = "Hollow Points", rarity = "rare", max = 3, mods = { critdmg = 0.75 },         lines = { "+75% crit damage" } },
  { id = "plate",   name = "Armor Plate",   rarity = "rare", max = 3, mods = { armor = 1.5, speed_pct = -0.08 }, lines = { "+1.5 armor", "!-8% move speed" } },
  { id = "saw",     name = "Buzzsaw",       rarity = "rare", max = 4, mods = { saws = 1 },               lines = { "+1 saw spinning around you" } },
  { id = "aura",    name = "Toxic Aura",    rarity = "rare", max = 4, mods = { aura = 1 },               lines = { "Poison pulse hurts mobs near you" } },
  { id = "w2",      name = "Shotgun",       rarity = "rare", max = 1, mods = {}, weapon = 2, lines = { "New weapon on key 2", "5 pellets, short range" } },
  { id = "w3",      name = "SMG",           rarity = "rare", max = 1, mods = {}, weapon = 3, lines = { "New weapon on key 3", "Bullet hose" } },
  { id = "w4",      name = "Launcher",      rarity = "rare", max = 1, mods = {}, weapon = 4, lines = { "New weapon on key 4", "Explosive rockets" } },
  -- explosion line
  { id = "exround", name = "Explosive Rounds", rarity = "rare", max = 3, mods = { exround = 1, rate_pct = -0.15 }, lines = { "Bullets blast on hit", "!-15% fire rate" } },
  { id = "bigbang", name = "Big Bang",      rarity = "rare", max = 4, mods = { area_pct = 0.25 },        lines = { "+25% explosion and spell size" } },
  { id = "mortar",  name = "Mortar",        rarity = "rare", max = 4, mods = { mortar = 1 },             lines = { "+1 shell every 2s on a mob" } },
  -- tank line
  { id = "spike",   name = "Spiked Armor",  rarity = "rare", max = 3, mods = { thorns = 1 },             lines = { "Getting hit blasts mobs around you", "Damage grows with armor" } },
  { id = "leech",   name = "Leech Rounds",  rarity = "rare", max = 3, mods = { lifesteal = 0.01 },       lines = { "Heal 1% of damage dealt" } },
  { id = "eshield", name = "Energy Shield", rarity = "rare", max = 3, mods = { shield = 1 },             lines = { "Blocks a hit every 12s", "More copies recharge faster" } },
  -- mage line
  { id = "firering", name = "Fire Ring",    rarity = "rare", max = 5, mods = { firering = 1 },           lines = { "Ring of flames burns mobs near you", "Bigger and hotter per level" } },
  { id = "meteor",  name = "Meteor",        rarity = "rare", max = 4, mods = { meteor = 1 },             lines = { "Meteor hits the biggest crowd", "+1 meteor per level" } },
  { id = "frost",   name = "Frost Nova",    rarity = "rare", max = 3, mods = { frost = 1 },              lines = { "Every 6s freeze mobs near you" } },
  { id = "thunder", name = "Thunderstorm",  rarity = "rare", max = 4, mods = { thunder = 1 },            lines = { "Lightning strikes random mobs", "Shocked mobs take +25% dmg" } },
  { id = "orbs",    name = "Arcane Orbs",   rarity = "rare", max = 4, mods = { orbs = 1 },               lines = { "+1 homing orb every second" } },

  ---------------------------------------------------------------- epic (big power, real cost)
  { id = "glass",     name = "Glass Cannon", rarity = "epic", max = 2, mods = { dmg_x = 2, maxhp_x = 0.5 }, lines = { "x2 all damage", "!-50% max HP" } },
  { id = "blood",     name = "Blood Pact",   rarity = "epic", max = 2, mods = { bloodpact = 0.05 },  lines = { "+5% damage per missing HP" } },
  { id = "greed",     name = "Greed",        rarity = "epic", max = 2, mods = { xp_pct = 0.6, spawn_pct = 0.3 }, lines = { "+60% XP", "!+30% more mobs" } },
  { id = "overclock", name = "Overclock",    rarity = "epic", max = 2, mods = { rate_x = 1.5, drain = 1 }, lines = { "x1.5 fire rate", "!Lose 1 HP every 20s" } },
  { id = "coil",      name = "Storm Coil",   rarity = "epic", max = 3, mods = { chain = 0.15 },      lines = { "15% on hit: zap 3 nearby mobs" } },
  { id = "split",     name = "Splitter",     rarity = "epic", max = 2, mods = { split = 1 },         lines = { "Bullets split in 2 on hit" } },
  { id = "rico",      name = "Ricochet",     rarity = "epic", max = 3, mods = { ricochet = 1 },      lines = { "Bullets bounce to another mob" } },
  { id = "corpse",    name = "Corpse Bomb",  rarity = "epic", max = 3, mods = { corpse = 0.25 },     lines = { "25% chance: kills explode" } },
  { id = "demo",      name = "Demolitions",  rarity = "epic", max = 2, mods = { aoedmg_x = 2, gundmg_x = 0.6 }, lines = { "x2 area damage", "!x0.6 gun damage" } },
  { id = "marks",     name = "Marksman",     rarity = "epic", max = 2, mods = { gundmg_x = 1.8, aoedmg_x = 0.5 }, lines = { "x1.8 gun damage", "!x0.5 area damage" } },
  { id = "shrap",     name = "Shrapnel",     rarity = "epic", max = 2, mods = { shrapnel = 5 },      lines = { "Explosions throw 5 fragments" } },
  { id = "napalm",    name = "Napalm",       rarity = "epic", max = 2, mods = { napalm = 1 },        lines = { "Explosions leave burning ground" } },
  { id = "jugg",      name = "Juggernaut",   rarity = "epic", max = 2, mods = { maxhp_x = 2, speed_pct = -0.2 }, lines = { "x2 max HP", "!-20% move speed" } },
  { id = "retal",     name = "Retaliation",  rarity = "epic", max = 2, mods = { retal = 1 },         lines = { "x2 damage for 3s after a hit" } },
  { id = "pyro",      name = "Pyromaniac",   rarity = "epic", max = 2, mods = { pyro = 0.3, burn_x = 1.5 }, lines = { "Burning mobs take +30% damage", "x1.5 burn damage" } },
  { id = "permafrost", name = "Permafrost",  rarity = "epic", max = 1, mods = { permafrost = 0.4 },  lines = { "Frozen / chilled mobs take", "+40% damage" } },
  { id = "conductor", name = "Conductor",    rarity = "epic", max = 1, mods = { conductor = 0.5 },   lines = { "Shocked mobs take another +50%", "Storm Coil zaps also shock" } },

  ---------------------------------------------------------------- legendary
  { id = "hell",   name = "Bullet Hell",    rarity = "legendary", max = 1, mods = { proj = 3, gundmg_x = 0.6 }, lines = { "+3 projectiles", "!-40% gun damage" } },
  { id = "vamp",   name = "Vampire Fangs",  rarity = "legendary", max = 1, mods = { lifesteal = 0.03, regen_x = 0 }, lines = { "Heal 3% of damage dealt", "!No HP regen" } },
  { id = "exec",   name = "Executioner",    rarity = "legendary", max = 1, mods = { crit = 0.12, critdmg = 1.5 }, lines = { "+12% crit chance", "+150% crit damage" } },
  { id = "midas",  name = "Midas Crown",    rarity = "legendary", max = 1, mods = { luck = 3, xp_pct = 0.3, spawn_pct = 0.2 }, lines = { "Much rarer items", "+30% XP", "!+20% more mobs" } },
  { id = "chainre", name = "Chain Reaction", rarity = "legendary", max = 1, mods = { chainreact = 0.3 }, lines = { "30%: explosions set off", "another one nearby" } },
  { id = "bulwark", name = "Bulwark",       rarity = "legendary", max = 1, mods = { bulwark = 0.01 },  lines = { "+1% damage per max HP" } },
  { id = "wind",   name = "Second Wind",    rarity = "legendary", max = 1, mods = { revive = 1 },      lines = { "Revive once at 50% HP" } },
  { id = "archmage", name = "Archmage",     rarity = "legendary", max = 1, mods = { aoedmg_x = 2, gundmg_x = 0.5 }, lines = { "x2 area + spell damage", "!x0.5 gun damage" } },

  ---------------------------------------------------------------- evolutions (appear when requirements are met)
  { id = "sawstorm", name = "Saw Storm",     rarity = "legendary", max = 1, req = { saw = 4, charm = 1 },  mods = { saws = 4, sawdmg_x = 2 },     lines = { "EVOLUTION", "+4 saws", "x2 saw damage" } },
  { id = "nuke",     name = "Nuke Launcher", rarity = "legendary", max = 1, req = { w4 = 1, heavy = 1 },   mods = { area_x = 1.8, boom_x = 1.6 }, lines = { "EVOLUTION", "x1.8 explosion size", "x1.6 explosion damage" } },
  { id = "plague",   name = "Plague Heart",  rarity = "legendary", max = 1, req = { aura = 4, bandage = 1 }, mods = { aura = 3, regen = 2 },      lines = { "EVOLUTION", "+3 aura levels", "+2 HP every 10s" } },
  { id = "maiden",   name = "Iron Maiden",   rarity = "legendary", max = 1, req = { spike = 3, plate = 1 }, mods = { thornpulse = 1, armor = 2 }, lines = { "EVOLUTION", "Thorns blast every 2s", "+2 armor" } },
  { id = "inferno",  name = "Inferno",       rarity = "legendary", max = 1, req = { firering = 5, bigbang = 1 }, mods = { fireringdmg_x = 2.5, area_pct = 0.3 }, lines = { "EVOLUTION", "x2.5 Fire Ring damage", "+30% size" } },
  { id = "armageddon", name = "Armageddon",  rarity = "legendary", max = 1, req = { meteor = 4, demo = 1 }, mods = { meteor = 3, meteordmg_x = 1.5 }, lines = { "EVOLUTION", "+3 meteors", "x1.5 meteor damage" } },
  { id = "zero",     name = "Absolute Zero", rarity = "legendary", max = 1, req = { frost = 3, permafrost = 1 }, mods = { frostcd_x = 0.5, frost = 1 }, lines = { "EVOLUTION", "Frost Nova every 3s", "+1 nova level" } },
}

I.SNACK = { id = "snack", name = "Snack", rarity = "common", max = 999, mods = {}, lines = { "Heal 5 HP" }, heal = 5, parsed = {} }

local function parseMods(mods, where)
  local out = {}
  for k, v in pairs(mods) do
    local stat, kind = k:match("^(.-)_(pct)$")
    if not stat then stat, kind = k:match("^(.-)_(x)$") end
    if not stat then stat, kind = k, "flat" end
    if I.BASE[stat] == nil then error(where .. " has unknown stat " .. stat) end
    out[#out + 1] = { stat, kind, v }
  end
  return out
end
I.parseMods = parseMods

I.byId = { snack = I.SNACK }
for _, it in ipairs(I.LIST) do
  I.byId[it.id] = it
  it.parsed = parseMods(it.mods, "item " .. it.id)
end

-- owned: id -> stacks.  extra: list of { stat, kind, value, times } (skill tree)
function I.compute(owned, extra)
  local flat, pct, mul = {}, {}, {}
  for k in pairs(I.BASE) do flat[k], pct[k], mul[k] = 0, 0, 1 end
  local function add(stat, kind, v, n)
    if kind == "flat" then flat[stat] = flat[stat] + v * n
    elseif kind == "pct" then pct[stat] = pct[stat] + v * n
    else mul[stat] = mul[stat] * (v ^ n) end
  end
  for id, n in pairs(owned) do
    local it = I.byId[id]
    if it then
      for _, m in ipairs(it.parsed) do add(m[1], m[2], m[3], n) end
    end
  end
  if extra then
    for _, m in ipairs(extra) do add(m[1], m[2], m[3], m[4]) end
  end
  local out = {}
  for k, base in pairs(I.BASE) do
    out[k] = (base + flat[k]) * math.max(0, 1 + pct[k]) * mul[k]
  end
  return out
end

-- armor: each point is worth a bit less than the last, no hard cap
function I.armorReduction(armor)
  if armor <= 0 then return 0 end
  return armor / (armor + 6)
end

local function available(it, owned, banned)
  if banned and banned[it.id] then return false end
  if (owned[it.id] or 0) >= it.max then return false end
  if it.req then
    for rid, need in pairs(it.req) do
      if (owned[rid] or 0) < need then return false end
    end
  end
  return true
end

local function rarityIndex(r)
  for i, name in ipairs(I.RARITY_ORDER) do if name == r then return i end end
  return 1
end

-- roll n distinct offers; minRarity e.g. "epic" for chests; banned = set of ids; exclude = set of ids
function I.roll(owned, luck, n, minRarity, banned, exclude)
  local minIdx = minRarity and rarityIndex(minRarity) or 1
  local boost = { common = 1, rare = 1 + luck * 0.3, epic = 1 + luck * 0.6, legendary = 1 + luck }
  local pool = {}
  for _, it in ipairs(I.LIST) do
    if available(it, owned, banned) and not (exclude and exclude[it.id]) and rarityIndex(it.rarity) >= minIdx then
      local w = I.RARITY[it.rarity].weight * boost[it.rarity]
      if it.req then w = 40 end
      pool[#pool + 1] = { it = it, w = w }
    end
  end
  local picks = {}
  while #picks < n and #pool > 0 do
    local total = 0
    for _, e in ipairs(pool) do total = total + e.w end
    local r = math.random() * total
    local idx = #pool
    for i, e in ipairs(pool) do
      r = r - e.w
      if r <= 0 then idx = i; break end
    end
    picks[#picks + 1] = table.remove(pool, idx).it
  end
  while #picks < n do picks[#picks + 1] = I.SNACK end
  return picks
end

-- random item of a given rarity that the player can still take
function I.randomOf(owned, rarity, filter)
  local pool = {}
  for _, it in ipairs(I.LIST) do
    if it.rarity == rarity and not it.req and available(it, owned) and (not filter or filter(it)) then
      pool[#pool + 1] = it
    end
  end
  if #pool == 0 then return nil end
  return pool[math.random(#pool)]
end

return I
