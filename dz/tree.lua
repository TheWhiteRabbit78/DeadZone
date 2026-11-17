-- DEAD ZONE skill tree (permanent upgrades bought with souls) + prestige.
--
-- Layout: root in the middle, four branches.
--   Firepower (up)   guns, crits          Fortune  (down)  speed, XP, souls, loot
--   Arcana    (left) area, spells          Fortitude (right) HP, armor, sustain
-- x, y are grid positions; a node needs its parent at level 1+.
-- key = keystone: big one-off node, NOT carried over by prestige.
-- start = item given at the start of every run.
--
-- Prestige (needs every node maxed): resets the tree, keeps 10% of every
-- non-keystone node's max bonus per prestige (max 10 = a free full tree),
-- gives more souls, and makes the undead tougher.

local T = {}

T.COST_SCALE = 0.59     -- first full tree ~50k souls (about 30-50 hours of runs)
T.MAX_PRESTIGE = 10

T.BRANCH_COL = { root = "g", fire = "O", arcana = "C", fort = "R", fortune = "Y" }

local N = {}
local function node(id, name, branch, x, y, max, parent, mods, desc, opt)
  local n = { id = id, name = name, branch = branch, x = x, y = y, max = max,
              parent = parent, mods = mods or {}, desc = desc }
  if opt then for k, v in pairs(opt) do n[k] = v end end
  N[#N + 1] = n
end

node("root", "Awakening", "root", 0, 0, 1, nil, { maxhp = 1 }, "+10 max HP. The journey starts here", { key = true })

-- Firepower -----------------------------------------------------------------
node("f_might",   "Might",          "fire", 0, -1, 10, "root",    { gundmg_pct = 0.02 }, "+2% gun damage")
node("f_trigger", "Trigger Disc.",  "fire", 0, -2, 10, "f_might", { rate_pct = 0.02 },   "+2% fire rate")
node("f_sharp",   "Sharpshooter",   "fire", -1, -2, 10, "f_trigger", { crit = 0.01 },    "+1% crit chance")
node("f_range",   "Long Range",     "fire", 1, -2, 5,  "f_trigger", { range_pct = 0.04 }, "+4% range")
node("f_lethal",  "Lethality",      "fire", 0, -3, 10, "f_trigger", { critdmg = 0.05 },  "+5% crit damage")
node("f_pierce",  "Penetrator",     "fire", -1, -3, 1, "f_lethal",  { pierce = 1 },      "KEYSTONE: bullets pierce +1", { key = true })
node("f_hunter",  "Hunter",         "fire", -2, -3, 10, "f_pierce", { dmg_pct = 0.02 },  "+2% all damage")
node("f_arsenal", "Arsenal",        "fire", 1, -3, 1,  "f_lethal",  {}, "KEYSTONE: start with a random extra weapon", { key = true, start = "weapon" })
node("f_brutal",  "Brutality",      "fire", 0, -4, 10, "f_lethal",  { dmg_pct = 0.02 },  "+2% all damage")
node("f_twin",    "Twin Barrels",   "fire", -1, -4, 1, "f_brutal",  { proj = 1 },        "KEYSTONE: +1 projectile", { key = true })
node("f_armory",  "Armory",         "fire", 1, -4, 1,  "f_brutal",  {}, "KEYSTONE: start with a random rare item", { key = true, start = "rare" })
node("f_quick",   "Quickdraw",      "fire", 2, -4, 5,  "f_armory",  { rate_pct = 0.03 }, "+3% fire rate")
node("f_dead",    "Deadeye",        "fire", 0, -5, 5,  "f_brutal",  { crit = 0.02 },     "+2% crit chance")
node("f_overkill","Overkill",       "fire", -1, -5, 5, "f_dead",    { critdmg = 0.1 },   "+10% crit damage")
node("f_gunnut",  "Gun Nut",        "fire", 1, -5, 5,  "f_dead",    { gundmg_pct = 0.04 }, "+4% gun damage")
node("f_apex",    "GUNMASTER",      "fire", 0, -6, 3,  "f_dead",    { gundmg_x = 1.15 }, "APEX: x1.15 gun damage")

-- Arcana ------------------------------------------------------------------------
node("a_power",   "Spellpower",     "arcana", -1, 0, 10, "root",    { aoedmg_pct = 0.02 }, "+2% area damage")
node("a_radius",  "Blast Radius",   "arcana", -2, 0, 10, "a_power", { area_pct = 0.02 },   "+2% explosion/spell size")
node("a_pyro",    "Pyromancy",      "arcana", -2, -1, 5, "a_radius", { burn_pct = 0.05 },  "+5% burn damage")
node("a_frost",   "Frostbite",      "arcana", -2, 1, 5,  "a_radius", { permafrost = 0.04 }, "Frozen mobs take +4% damage")
node("a_focus",   "Focus",          "arcana", -3, 0, 10, "a_radius", { cdr_pct = -0.02 },  "Spells recharge 2% faster")
node("a_kindle",  "Kindling",       "arcana", -3, -1, 1, "a_focus", {}, "KEYSTONE: start with Fire Ring", { key = true, start = "firering" })
node("a_static",  "Static",         "arcana", -3, 1, 5,  "a_focus", { conductor = 0.05 }, "Shocked mobs take +5% damage")
node("a_mastery", "Arcane Mastery", "arcana", -4, 0, 10, "a_focus", { aoedmg_pct = 0.03 }, "+3% area damage")
node("a_star",    "Starfall",       "arcana", -4, -1, 5, "a_mastery", { meteordmg_pct = 0.1 }, "+10% meteor damage")
node("a_archon",  "Archon",         "arcana", -5, -1, 1, "a_star", {}, "KEYSTONE: start with a random spell", { key = true, start = "spell" })
node("a_demo",    "Demo Expert",    "arcana", -4, 1, 5,  "a_mastery", { boom_pct = 0.05 }, "+5% explosion damage")
node("a_wild",    "Wildfire",       "arcana", -5, 0, 5,  "a_mastery", { fireringdmg_pct = 0.1 }, "+10% Fire Ring damage")
node("a_thunder", "Thunderhead",    "arcana", -5, 1, 5,  "a_wild",  { chain = 0.01 },      "+1% chain lightning chance")
node("a_apex",    "ARCHMAGE",       "arcana", -6, 0, 3,  "a_wild",  { aoedmg_x = 1.15 },  "APEX: x1.15 area damage")

-- Fortitude -------------------------------------------------------------------
node("t_vital",   "Vitality",       "fort", 1, 0, 10, "root",    { maxhp = 2 },       "+20 max HP")
node("t_tough",   "Toughness",      "fort", 2, 0, 10, "t_vital", { armor = 0.3 },     "+0.3 armor")
node("t_recov",   "Recovery",       "fort", 2, -1, 6, "t_tough", { regen = 0.3 },     "+3 HP every 10s")
node("t_evade",   "Evasion",        "fort", 2, 1, 10, "t_tough", { dodge = 0.01 },    "+1% dodge")
node("t_hide",    "Thick Hide",     "fort", 3, 0, 10, "t_tough", { maxhp_pct = 0.03 }, "+3% max HP")
node("t_leech",   "Leech",          "fort", 3, -1, 5, "t_hide",  { lifesteal = 0.002 }, "Heal 0.2% of damage dealt")
node("t_thorns",  "Thorns",         "fort", 3, 1, 5,  "t_hide",  { thorns = 0.2 },    "+20% thorns blast power")
node("t_guard",   "Guardian",       "fort", 4, 0, 5,  "t_hide",  { iframes_pct = 0.1 }, "+10% invulnerability after hits")
node("t_shield",  "Shield Training","fort", 4, -1, 1, "t_guard", {}, "KEYSTONE: start with Energy Shield", { key = true, start = "eshield" })
node("t_retal",   "Retaliator",     "fort", 5, -1, 5, "t_shield", { retal = 0.1 },    "+10% Retaliation power")
node("t_plating", "Bulwark Plating","fort", 4, 1, 5,  "t_guard", { armor = 0.5 },     "+0.5 armor")
node("t_life",    "Second Life",    "fort", 5, 0, 1,  "t_guard", { revive = 1 },      "KEYSTONE: revive once per run", { key = true })
node("t_iron",    "Iron Body",      "fort", 5, 1, 5,  "t_life",  { maxhp = 3 },       "+30 max HP")
node("t_apex",    "COLOSSUS",       "fort", 6, 0, 3,  "t_life",  { maxhp_x = 1.15 },  "APEX: x1.15 max HP")

-- Fortune -----------------------------------------------------------------------
node("l_swift",   "Swiftness",      "fortune", 0, 1, 10, "root",    { speed_pct = 0.02 }, "+2% move speed")
node("l_scholar", "Scholar",        "fortune", 0, 2, 10, "l_swift", { xp_pct = 0.03 },    "+3% XP")
node("l_magnet",  "Magnetism",      "fortune", -1, 2, 6, "l_scholar", { magnet_pct = 0.05 }, "+5% pickup range")
node("l_siphon",  "Soul Siphon",    "fortune", 1, 2, 10, "l_scholar", { souls_pct = 0.05 }, "+5% souls per run")
node("l_luck",    "Fortune",        "fortune", 0, 3, 10, "l_scholar", { luck = 0.2 },     "+0.2 luck (rarer items)")
node("l_reroll",  "Reroller",       "fortune", -1, 3, 5, "l_luck",  { rerolls = 1 },      "+1 reroll per run")
node("l_banish",  "Banisher",       "fortune", 1, 3, 5,  "l_luck",  { banish = 1 },       "+1 banish per run")
node("l_treasure","Treasure Hunter","fortune", 0, 4, 5,  "l_luck",  { drops_pct = 0.1 },  "+10% heart/magnet drops")
node("l_choice",  "Wider Choice",   "fortune", -1, 4, 1, "l_treasure", { choices = 1 },   "KEYSTONE: 4 cards on level up", { key = true })
node("l_double",  "Double Loot",    "fortune", 1, 4, 1,  "l_treasure", { bosschests = 1 }, "KEYSTONE: bosses drop 2 chests", { key = true })
node("l_reaper",  "Soul Reaper",    "fortune", 2, 4, 5,  "l_double", { souls_pct = 0.1 },  "+10% souls per run")
node("l_head",    "Head Start",     "fortune", 0, 5, 3,  "l_treasure", { headstart = 1 }, "+1 free level up at run start")
node("l_fleet",   "Fleet Foot",     "fortune", -1, 5, 5, "l_head",  { speed_pct = 0.03 },  "+3% move speed")
node("l_apex",    "ASCENDANT",      "fortune", 0, 6, 3,  "l_head",  { xp_x = 1.1, souls_x = 1.1 }, "APEX: x1.1 XP and souls")

T.NODES = N
T.byId = {}
local I = require("dz.items")
for _, n in ipairs(N) do
  T.byId[n.id] = n
  n.parsed = I.parseMods(n.mods, "tree node " .. n.id)
  -- depth = distance from root, drives cost
  n.depth = math.abs(n.x) + math.abs(n.y)
end

-- cost of buying level `lvl` (1-based) of node n
function T.cost(n, lvl)
  local base = 10 * (n.depth ^ 1.6) + 6
  if n.key then
    base = base * 8
  elseif n.max <= 3 then
    base = base * 4                  -- apex nodes
  end
  local growth = (n.max >= 10) and 1.22 or 1.35
  return math.floor(base * growth ^ (lvl - 1) * T.COST_SCALE + 0.5)
end

function T.totalCost()
  local sum = 0
  for _, n in ipairs(N) do
    for l = 1, n.max do sum = sum + T.cost(n, l) end
  end
  return sum
end

function T.totalLevels()
  local sum = 0
  for _, n in ipairs(N) do sum = sum + n.max end
  return sum
end

function T.unlocked(n, levels)
  if not n.parent then return true end
  return (levels[n.parent] or 0) >= 1
end

function T.allMaxed(levels)
  for _, n in ipairs(N) do
    if (levels[n.id] or 0) < n.max then return false end
  end
  return true
end

-- stat mods for I.compute: owned levels + prestige carry-over
function T.mods(levels, prestige)
  local out = {}
  for _, n in ipairs(N) do
    local eff = levels[n.id] or 0
    if not n.key then eff = eff + (prestige or 0) * 0.1 * n.max end
    if eff > 0 then
      for _, m in ipairs(n.parsed) do out[#out + 1] = { m[1], m[2], m[3], eff } end
    end
  end
  return out
end

-- start-of-run perks from keystones
function T.starts(levels)
  local s = {}
  for _, n in ipairs(N) do
    if n.start and (levels[n.id] or 0) >= 1 then s[#s + 1] = n.start end
  end
  return s
end

-- difficulty + reward scaling per prestige
function T.prestigeMobHp(p) return 1 + 0.2 * p end
function T.prestigeMobSpeed(p) return 1 + 0.03 * p end
function T.prestigeSouls(p) return 1 + 0.25 * p end

return T
