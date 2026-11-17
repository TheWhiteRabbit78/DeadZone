-- DEAD ZONE items: the build system.
--
-- Every stat is computed as:   (base + flat) * (1 + pct) * mult
--   mods = { dmg_pct = 0.12 }  -> +12% (additive with other % bonuses)
--   mods = { dmg_x = 1.6 }     -> x1.6 (multiplies with everything; stacks exponentially)
--   mods = { proj = 1 }        -> flat +1
-- Strong multipliers come with a drawback. Lines starting with "!" are drawbacks (shown red).

local I = {}

I.RARITY = {
  common    = { name = "COMMON",    col = "W", weight = 60 },
  rare      = { name = "RARE",      col = "C", weight = 28 },
  epic      = { name = "EPIC",      col = "O", weight = 10 },
  legendary = { name = "LEGENDARY", col = "Y", weight = 2.5 },
}
I.RARITY_ORDER = { "common", "rare", "epic", "legendary" }

I.BASE = {
  dmg = 1, rate = 1, proj = 0, pierce = 0, range = 1, speed = 1, maxhp = 10,
  regen = 0, armor = 0, dodge = 0, crit = 0.05, critdmg = 2, magnet = 28, xp = 1,
  luck = 0, area = 1, boom = 1, spawn = 1, drain = 0, bloodpact = 0, chain = 0,
  split = 0, ricochet = 0, corpse = 0, saws = 0, sawdmg = 1, aura = 0, lifesteal = 0,
}

I.LIST = {
  ---------------------------------------------------------------- common
  { id = "sharp",   name = "Sharpened Rounds", rarity = "common", max = 5, mods = { dmg_pct = 0.12 },   lines = { "+12% damage" } },
  { id = "oil",     name = "Oiled Trigger",    rarity = "common", max = 5, mods = { rate_pct = 0.10 },  lines = { "+10% fire rate" } },
  { id = "boots",   name = "Running Boots",    rarity = "common", max = 4, mods = { speed_pct = 0.10 }, lines = { "+10% move speed" } },
  { id = "skin",    name = "Thick Skin",       rarity = "common", max = 5, mods = { maxhp = 3 },        lines = { "+3 max HP" }, heal = 3 },
  { id = "charm",   name = "Magnet Charm",     rarity = "common", max = 3, mods = { magnet_pct = 0.4 }, lines = { "+40% pickup range" } },
  { id = "scope",   name = "Scope",            rarity = "common", max = 3, mods = { range_pct = 0.2 },  lines = { "+20% range" } },
  { id = "bandage", name = "Bandages",         rarity = "common", max = 3, mods = { regen = 1 },        lines = { "+1 HP every 10s" } },
  { id = "coin",    name = "Lucky Coin",       rarity = "common", max = 4, mods = { crit = 0.05, luck = 0.5 }, lines = { "+5% crit chance", "+luck (rarer items)" } },
  { id = "notes",   name = "Study Notes",      rarity = "common", max = 3, mods = { xp_pct = 0.15 },    lines = { "+15% XP" } },

  ---------------------------------------------------------------- rare
  { id = "barrel",  name = "Extra Barrel",  rarity = "rare", max = 3, mods = { proj = 1, dmg_pct = -0.10 }, lines = { "+1 projectile", "!-10% damage" } },
  { id = "ap",      name = "AP Rounds",     rarity = "rare", max = 3, mods = { pierce = 1 },             lines = { "Bullets pierce +1 enemy" } },
  { id = "heavy",   name = "Heavy Rounds",  rarity = "rare", max = 3, mods = { dmg_x = 1.6, rate_x = 0.75 }, lines = { "x1.6 damage", "!-25% fire rate" } },
  { id = "hair",    name = "Hair Trigger",  rarity = "rare", max = 3, mods = { rate_x = 1.8, dmg_x = 0.7 },  lines = { "x1.8 fire rate", "!-30% damage" } },
  { id = "hollow",  name = "Hollow Points", rarity = "rare", max = 3, mods = { critdmg = 0.75 },         lines = { "+75% crit damage" } },
  { id = "plate",   name = "Armor Plate",   rarity = "rare", max = 3, mods = { armor = 1, speed_pct = -0.08 }, lines = { "-15% damage taken", "!-8% move speed" } },
  { id = "saw",     name = "Buzzsaw",       rarity = "rare", max = 4, mods = { saws = 1 },               lines = { "+1 saw spinning around you" } },
  { id = "aura",    name = "Toxic Aura",    rarity = "rare", max = 4, mods = { aura = 1 },               lines = { "Poison pulse hurts mobs near you" } },
  { id = "w2",      name = "Shotgun",       rarity = "rare", max = 1, mods = {}, weapon = 2, lines = { "New weapon on key 2", "5 pellets, short range" } },
  { id = "w3",      name = "SMG",           rarity = "rare", max = 1, mods = {}, weapon = 3, lines = { "New weapon on key 3", "Bullet hose" } },
  { id = "w4",      name = "Launcher",      rarity = "rare", max = 1, mods = {}, weapon = 4, lines = { "New weapon on key 4", "Explosive rockets" } },

  ---------------------------------------------------------------- epic (big power, real cost)
  { id = "glass",     name = "Glass Cannon", rarity = "epic", max = 2, mods = { dmg_x = 2, maxhp_x = 0.5 }, lines = { "x2 damage", "!-50% max HP" } },
  { id = "blood",     name = "Blood Pact",   rarity = "epic", max = 2, mods = { bloodpact = 0.05 },  lines = { "+5% damage per missing HP" } },
  { id = "greed",     name = "Greed",        rarity = "epic", max = 2, mods = { xp_pct = 0.6, spawn_pct = 0.3 }, lines = { "+60% XP", "!+30% more mobs" } },
  { id = "overclock", name = "Overclock",    rarity = "epic", max = 2, mods = { rate_x = 1.5, drain = 1 }, lines = { "x1.5 fire rate", "!Lose 1 HP every 20s" } },
  { id = "coil",      name = "Storm Coil",   rarity = "epic", max = 3, mods = { chain = 0.15 },      lines = { "15% on hit: zap 3 nearby mobs" } },
  { id = "split",     name = "Splitter",     rarity = "epic", max = 2, mods = { split = 1 },         lines = { "Bullets split in 2 on hit" } },
  { id = "rico",      name = "Ricochet",     rarity = "epic", max = 3, mods = { ricochet = 1 },      lines = { "Bullets bounce to another mob" } },
  { id = "corpse",    name = "Corpse Bomb",  rarity = "epic", max = 3, mods = { corpse = 0.25 },     lines = { "25% chance: kills explode" } },

  ---------------------------------------------------------------- legendary
  { id = "hell",   name = "Bullet Hell",   rarity = "legendary", max = 1, mods = { proj = 3, dmg_x = 0.6 }, lines = { "+3 projectiles", "!-40% damage" } },
  { id = "vamp",   name = "Vampire Fangs", rarity = "legendary", max = 1, mods = { lifesteal = 0.03, regen_x = 0 }, lines = { "Heal 3% of damage dealt", "!No HP regen" } },
  { id = "exec",   name = "Executioner",   rarity = "legendary", max = 1, mods = { crit = 0.12, critdmg = 1.5 }, lines = { "+12% crit chance", "+150% crit damage" } },
  { id = "midas",  name = "Midas Crown",   rarity = "legendary", max = 1, mods = { luck = 3, xp_pct = 0.3, spawn_pct = 0.2 }, lines = { "Much rarer items", "+30% XP", "!+20% more mobs" } },

  ---------------------------------------------------------------- evolutions (appear when requirements are met)
  { id = "sawstorm", name = "Saw Storm",     rarity = "legendary", max = 1, req = { saw = 4, charm = 1 },  mods = { saws = 4, sawdmg_x = 2 },        lines = { "EVOLUTION", "+4 saws", "x2 saw damage" } },
  { id = "nuke",     name = "Nuke Launcher", rarity = "legendary", max = 1, req = { w4 = 1, heavy = 1 },   mods = { area_x = 1.8, boom_x = 1.6 },    lines = { "EVOLUTION", "x1.8 explosion size", "x1.6 explosion damage" } },
  { id = "plague",   name = "Plague Heart",  rarity = "legendary", max = 1, req = { aura = 4, bandage = 1 }, mods = { aura = 3, regen = 2 },          lines = { "EVOLUTION", "+3 aura levels", "+2 HP every 10s" } },
}

I.SNACK = { id = "snack", name = "Snack", rarity = "common", max = 999, mods = {}, lines = { "Heal 5 HP" }, heal = 5 }

I.byId = { snack = I.SNACK }
for _, it in ipairs(I.LIST) do
  I.byId[it.id] = it
  -- pre-parse mods: key -> stat, kind
  it.parsed = {}
  for k, v in pairs(it.mods) do
    local stat, kind = k:match("^(.-)_(pct)$")
    if not stat then stat, kind = k:match("^(.-)_(x)$") end
    if not stat then stat, kind = k, "flat" end
    if I.BASE[stat] == nil then error("item " .. it.id .. " has unknown stat " .. stat) end
    it.parsed[#it.parsed + 1] = { stat, kind, v }
  end
end

-- owned: id -> stack count. Returns final stats.
function I.compute(owned)
  local flat, pct, mul = {}, {}, {}
  for k in pairs(I.BASE) do flat[k], pct[k], mul[k] = 0, 0, 1 end
  for id, n in pairs(owned) do
    local it = I.byId[id]
    if it and it.parsed then
      for _, m in ipairs(it.parsed) do
        local stat, kind, v = m[1], m[2], m[3]
        if kind == "flat" then flat[stat] = flat[stat] + v * n
        elseif kind == "pct" then pct[stat] = pct[stat] + v * n
        else mul[stat] = mul[stat] * (v ^ n) end
      end
    end
  end
  local out = {}
  for k, base in pairs(I.BASE) do
    out[k] = (base + flat[k]) * math.max(0, 1 + pct[k]) * mul[k]
  end
  return out
end

local function available(it, owned)
  if (owned[it.id] or 0) >= it.max then return false end
  if it.req then
    for rid, need in pairs(it.req) do
      if (owned[rid] or 0) < need then return false end
    end
  end
  return true
end

-- roll n distinct offers. minRarity (optional) e.g. "epic" for chests.
function I.roll(owned, luck, n, minRarity)
  local minIdx = 1
  if minRarity then
    for i, r in ipairs(I.RARITY_ORDER) do if r == minRarity then minIdx = i end end
  end
  local boost = { common = 1, rare = 1 + luck * 0.3, epic = 1 + luck * 0.6, legendary = 1 + luck }
  local pool = {}
  for _, it in ipairs(I.LIST) do
    if available(it, owned) then
      local ri = 1
      for i, r in ipairs(I.RARITY_ORDER) do if r == it.rarity then ri = i end end
      if ri >= minIdx then
        local w = I.RARITY[it.rarity].weight * boost[it.rarity]
        if it.req then w = 40 end         -- evolutions show up quickly once unlocked
        pool[#pool + 1] = { it = it, w = w }
      end
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

return I
