--[[
  DEAD ZONE  v2  -  pixel-art roguelite survivor shooter for CC:Tweaked
  Advanced Computer + Advanced Monitor wall (max size 8x6 recommended)
  Optional: Speaker (sound), Player Detector (log in by right-clicking it)

  Keep the computer's screen open while playing - it's your controller.
    WASD        move (8 directions)
    SPACE       shoot where you face (hold for auto-fire)
    ARROWS      aim + shoot in that direction
    1 2 3 4     switch weapon
    1 2 3 (4)   pick an item on level up,  R reroll,  B banish
    P           pause (shows your build)
]]

local dir = fs.getDir(shell.getRunningProgram())
package.path = "/" .. dir .. "/?.lua;" .. package.path

local P = require("dz.palette")
local G = require("dz.gfx")
local SPR = require("dz.sprites")
local World = require("dz.world")
local I = require("dz.items")
local Tree = require("dz.tree")
local Prof = require("dz.profile")

local floor, ceil, sqrt, abs = math.floor, math.ceil, math.sqrt, math.abs
local min, max, random = math.min, math.max, math.random
local sin, cos, pi = math.sin, math.cos, math.pi
local atan2 = math.atan2 or math.atan

local TPS = 20
local MAX_MOBS = 160
local S = P.slot
local HEX = G.HEX

---------------------------------------------------------------------- display + peripherals
local native = term.current()
local mon = peripheral.find("monitor", function(_, m) return m.isColour() end)
local out = native
if mon then
  mon.setTextScale(0.5)
  out = mon
elseif not native.isColour() then
  error("DEAD ZONE needs an Advanced Computer / Advanced Monitor", 0)
end
P.apply(out)
local scr = G.new(out)
local PW, PH, CW, CH = scr.PW, scr.PH, scr.CW, scr.CH
local speaker = peripheral.find("speaker")
-- find the Player Detector by any type spelling (playerDetector / player_detector / ...)
local detector, detectorName
local function findDetector()
  detector, detectorName = nil, nil
  for _, name in ipairs(peripheral.getNames()) do
    for _, t in ipairs({ peripheral.getType(name) }) do
      if type(t) == "string" and t:lower():gsub("[_%s%-]", ""):find("playerdetector") then
        detector, detectorName = peripheral.wrap(name), name
        return
      end
    end
  end
end
findDetector()
Prof.init(dir)

---------------------------------------------------------------------- sprites
local spr = {}
for name, rows in pairs(SPR) do spr[name] = G.compile(rows) end
-- player shirt colour changes with prestige
local PRESTIGE_SHIRT = { "U", "C", "g", "Y", "O", "R", "W", "A", "Z", "N", "Y" }
local playerSpr = {}
for i, letter in ipairs(PRESTIGE_SHIRT) do
  local rows = {}
  for r, row in ipairs(SPR.player) do rows[r] = row:gsub("U", letter) end
  playerSpr[i - 1] = G.compile(rows)
end
local BLACK = G.pattern({ S.K, S.K, S.K, S.K, S.K, S.K })

-- tiny 3x5 pixel font for floating damage numbers
local DIGITS = {}
do
  local F = {
    ["0"] = { "WWW", "W.W", "W.W", "W.W", "WWW" }, ["1"] = { ".W.", "WW.", ".W.", ".W.", "WWW" },
    ["2"] = { "WWW", "..W", "WWW", "W..", "WWW" }, ["3"] = { "WWW", "..W", ".WW", "..W", "WWW" },
    ["4"] = { "W.W", "W.W", "WWW", "..W", "..W" }, ["5"] = { "WWW", "W..", "WWW", "..W", "WWW" },
    ["6"] = { "WWW", "W..", "WWW", "W.W", "WWW" }, ["7"] = { "WWW", "..W", ".W.", ".W.", ".W." },
    ["8"] = { "WWW", "W.W", "WWW", "W.W", "WWW" }, ["9"] = { "WWW", "W.W", "WWW", "..W", "WWW" },
    ["k"] = { "W..", "W.W", "WW.", "W.W", "W.W" }, ["M"] = { "W.W", "WWW", "WWW", "W.W", "W.W" },
    ["B"] = { "WW.", "W.W", "WW.", "W.W", "WW." }, ["."] = { ".", ".", ".", ".", "W" },
  }
  for ch, rows in pairs(F) do DIGITS[ch] = G.compile(rows) end
end

-- 1234 -> "1234", 12345 -> "12.3k", 1234567 -> "1.2M"
local function fmtNum(v)
  v = max(0, v)
  if v < 1000 then return tostring(floor(v + 0.5))
  elseif v < 1e5 then return ("%.1fk"):format(v / 1e3)
  elseif v < 1e6 then return floor(v / 1e3) .. "k"
  elseif v < 1e8 then return ("%.1fM"):format(v / 1e6)
  elseif v < 1e9 then return floor(v / 1e6) .. "M"
  else return ("%.1fB"):format(v / 1e9) end
end

---------------------------------------------------------------------- definitions
local WEAPONS = {
  { name = "Pistol",   dmg = 6,   cd = 6,  proj = 1, fan = 0.25, jitter = 0.05, speed = 6, range = 150, col = S.Y },
  { name = "Shotgun",  dmg = 4,   cd = 16, proj = 5, fan = 0.60, jitter = 0.12, speed = 5, range = 75,  col = S.O },
  { name = "SMG",      dmg = 2.5, cd = 2,  proj = 1, fan = 0.25, jitter = 0.20, speed = 7, range = 120, col = S.W },
  { name = "Launcher", dmg = 14,  cd = 26, proj = 1, fan = 0.35, jitter = 0.00, speed = 4, range = 170, col = S.R, aoe = 22 },
}

local MOBS = {
  zombie   = { spr = "zombie",   hp = 6,   speed = 0.55, dmg = 1, xp = 1,  score = 10,   r = 5,  unlock = 0 },
  ghoul    = { spr = "ghoul",    hp = 4,   speed = 1.25, dmg = 1, xp = 1,  score = 15,   r = 5,  unlock = 40,  intro = "GHOULS - fast and fragile!" },
  brute    = { spr = "brute",    hp = 40,  speed = 0.38, dmg = 2, xp = 5,  score = 50,   r = 7,  unlock = 100, heavy = true, intro = "BRUTES - they hit hard!" },
  skeleton = { spr = "skeleton", hp = 9,   speed = 0.5,  dmg = 1, xp = 2,  score = 25,   r = 5,  unlock = 150, ranged = true, intro = "SKELETONS - watch for arrows!" },
  bomb_imp = { spr = "bomb_imp", hp = 7,   speed = 0.9,  dmg = 3, xp = 2,  score = 25,   r = 5,  unlock = 210, bomb = true, intro = "BOMB IMPS - keep your distance!" },
  boss     = { spr = "boss",     hp = 500, speed = 0.5,  dmg = 3, xp = 60, score = 1000, r = 11, heavy = true, boss = true },
  nest     = { spr = "nest",     hp = 90,  speed = 0,    dmg = 0, xp = 25, score = 300,  r = 9,  heavy = true, static = true },
}
local SPAWN_ORDER = { "zombie", "ghoul", "brute", "skeleton", "bomb_imp" }
local DEATH_COL = { zombie = S.Z, ghoul = S.A, brute = S.Z, skeleton = S.W, bomb_imp = S.R, boss = S.W }
local SPELLS = { "firering", "meteor", "frost", "thunder", "orbs" }

---------------------------------------------------------------------- sound
local frame = 0
local sndCd = {}
local SOUNDS = {
  shoot = { 3,  function() speaker.playNote("hat", 0.35, 16) end },
  hit   = { 2,  function() speaker.playNote("snare", 0.25, 12) end },
  kill  = { 2,  function() speaker.playNote("basedrum", 0.6, 6) end },
  boom  = { 5,  function() speaker.playSound("entity.generic.explode", 0.5, 1.2) end },
  xp    = { 2,  function() speaker.playNote("chime", 0.3, random(16, 22)) end },
  level = { 10, function() speaker.playSound("entity.player.levelup", 0.7, 1) end },
  hurt  = { 6,  function() speaker.playSound("entity.player.hurt", 0.8, 1) end },
  boss  = { 40, function() speaker.playSound("entity.wither.spawn", 0.4, 1) end },
  pick  = { 4,  function() speaker.playNote("bell", 0.6, 18) end },
  zap   = { 3,  function() speaker.playNote("bit", 0.4, 20) end },
  frost = { 10, function() speaker.playSound("block.glass.break", 0.5, 1.4) end },
  shield = { 8, function() speaker.playNote("iron_xylophone", 0.6, 20) end },
  buy   = { 2,  function() speaker.playNote("pling", 0.7, 16) end },
  login = { 5,  function() speaker.playSound("entity.player.levelup", 0.5, 1.5) end },
}
local function sfx(kind)
  if not speaker then return end
  local d = SOUNDS[kind]
  if (sndCd[kind] or -999) + d[1] > frame then return end
  sndCd[kind] = frame
  pcall(d[2])
end

---------------------------------------------------------------------- state
-- everything about the current run lives in R, the logged-in player in prof
local state = "title"
local running = true
local held = {}
local prof = Prof.load("Guest")
local world
local p, R, stats, owned
local mobs, bullets, eshots, gems, pickups, parts, beams, strikes, fires, orbs
local UI = { showNums = true, msg = "", msgCol = S.Y, msgTimer = 0, shake = 0, treeSel = "root", prestigeArm = 0, nameBuf = "", board = {} }
local grid = {}

local function secs() return R.tick / TPS end
-- difficulty: gentle start, then compounding after minute 4
local function hpMul(s)
  local m = s / 60
  return (1 + 0.3 * m ^ 1.5) * 1.2 ^ max(0, m - 4) * 1.12 ^ max(0, m - 10) * Tree.prestigeMobHp(prof.prestige)
end
local function speedMul(s) return (1 + min(0.45, s / 800)) * Tree.prestigeMobSpeed(prof.prestige) end
local function mobDmg(s) return 1 + 0.15 * (s / 60) end                         -- mob hits +15% per minute
local function mobRes(s) return min(0.7, 0.03 * max(0, s / 60 - 3)) end       -- damage resistance
local function eliteChance(s) return (s < 300) and 0 or min(0.35, 0.04 * (s / 60 - 4)) end
local function allyScale(s) return 1 + 0.12 * (s / 60) end   -- soldiers/followers grow slower than mobs
local function mobCap(s) return 160 + min(20, floor(2 * s / 60)) end
local function xpFor(l) return floor(5 + l * 4 + l ^ 2) end
local function say(t, ticks, col) UI.msg, UI.msgTimer, UI.msgCol = t, ticks or 60, col or S.Y end

local function removeAt(list, i)
  local n = #list
  list[i] = list[n]
  list[n] = nil
end

local function recompute()
  stats = I.compute(owned, Tree.mods(prof.tree, prof.prestige), p.hpOrder)
  local newMax = max(0.5, stats.maxhp)
  p.maxHp = newMax
  if p.hp > newMax then p.hp = newMax end
end

local function login(name)
  if prof and prof.name == Prof.clean(name) then return end
  prof = Prof.load(name)
  UI.board = Prof.leaderboard(10)
  UI.treeSel = "root"
  say("Welcome, " .. prof.name .. "!", 60, S.g)
  sfx("login")
end

---------------------------------------------------------------------- run setup
local function giveItem(id)
  local it = I.byId[id]
  if not it then return end
  owned[id] = (owned[id] or 0) + 1
  if it.weapon then p.unlocked[it.weapon] = true end
  if I.hasHpMod(it) then p.hpOrder[#p.hpOrder + 1] = id end
end

local function newRun()
  world = World.new(spr, random(1, 99999))
  p = {
    x = 0, y = 0, vx = 0, vy = 0, knx = 0, kny = 0, fx = 1, fy = 0, flip = false,
    hp = 10, maxHp = 10, cd = 0, iframes = 0,
    xp = 0, level = 1, xpNext = xpFor(1), pending = 0, bonus = 0,
    weapon = 1, unlocked = { true, false, false, false },
    regenT = 0, drainT = 0, sawA = 0, auraT = 0, auraFlash = 0, moving = false,
    shieldT = 0, retalT = 0, revUsed = 0, thornT = 0, hpOrder = {},
  }
  R = {
    tick = 0, kills = 0, score = 0, bossKills = 0,
    spawnTimer = 20, nextHorde = 60 * TPS, nextBoss = 180 * TPS, boss = nil,
    announced = { zombie = true }, rerolls = 0, banishes = 0, banned = {},
    offers = nil, offerKind = nil, banishMode = false,
    deadTimer = 0, newBest = false, soulsEarned = 0, mult = 1, res = 0, nextSwarm = 360 * TPS, boomQ = {},
    spell = { meteor = 0, frost = 0, thunder = 0, orbs = 0, mortar = 0, ring = 0, fire = 0 },
    outposts = {}, activeOutposts = {}, followers = {}, survivor = nil, nextSurvivor = 180 * TPS,
    rescued = 0, nestsCleared = 0,
    dmgSrc = {}, dmgTick = 0, dmgHist = {}, dmgSum = 0, dps = 0, nums = {},
  }
  owned = {}
  mobs, bullets, eshots, gems, pickups, parts, beams, strikes, fires, orbs = {}, {}, {}, {}, {}, {}, {}, {}, {}, {}
  recompute()

  -- keystone start perks
  for _, s in ipairs(Tree.starts(prof.tree)) do
    if s == "weapon" then
      local w = I.randomOf(owned, "rare", function(it) return it.weapon ~= nil end)
      if w then giveItem(w.id) end
    elseif s == "rare" then
      local it = I.randomOf(owned, "rare", function(it) return not it.weapon end)
      if it then giveItem(it.id) end
    elseif s == "spell" then
      giveItem(SPELLS[random(#SPELLS)])
    else
      giveItem(s)
    end
  end
  recompute()
  p.hp = p.maxHp
  R.rerolls = floor(stats.rerolls + 0.5)
  R.banishes = floor(stats.banish + 0.5)
  p.bonus = floor(stats.headstart + 0.5)
  UI.shake = 0
  say("Survive!  WASD move, SPACE shoot", 80, S.W)
end

---------------------------------------------------------------------- particles
local function addPart(x, y, vx, vy, life, col)
  if #parts < 260 then parts[#parts + 1] = { x = x, y = y, vx = vx, vy = vy, life = life, col = col } end
end

local function burst(x, y, n, col, spd)
  for _ = 1, n do
    local a = random() * 2 * pi
    local v = (0.4 + random()) * (spd or 1.5)
    addPart(x, y, cos(a) * v, sin(a) * v, random(5, 12), col)
  end
end

local function ring(x, y, rad, n, col, spd)
  for i = 1, n do
    local a = i / n * 2 * pi
    addPart(x + cos(a) * rad * 0.3, y + sin(a) * rad * 0.3, cos(a) * spd, sin(a) * spd, floor(rad / spd * 0.7) + 2, col)
  end
end

---------------------------------------------------------------------- spatial grid (16 px cells, keyed by feet position)
local function gkey(gx, gy) return gx * 100003 + gy end

local function buildGrid()
  grid = {}
  for _, m in ipairs(mobs) do
    if not m.dead then
      local k = gkey(floor(m.x / 16), floor(m.y / 16))
      local l = grid[k]
      if not l then l = {}; grid[k] = l end
      l[#l + 1] = m
    end
  end
end

local function forNear(x, y, cells, fn)
  local gx, gy = floor(x / 16), floor(y / 16)
  for yy = gy - cells, gy + cells do
    for xx = gx - cells, gx + cells do
      local l = grid[gkey(xx, yy)]
      if l then
        for i = 1, #l do
          local m = l[i]
          if not m.dead and fn(m) then return end
        end
      end
    end
  end
end

local function nearestMob(x, y, maxD, exclude)
  local best, bd = nil, maxD * maxD
  for _, m in ipairs(mobs) do
    if not m.dead and not (exclude and exclude[m]) then
      local dx, dy = m.x - x, (m.y - 6) - y
      local d = dx * dx + dy * dy
      if d < bd then best, bd = m, d end
    end
  end
  return best
end

-- a random live mob within maxD of the player (optionally preferring crowds)
local function pickTarget(maxD, crowd)
  local cands = {}
  for _, m in ipairs(mobs) do
    if not m.dead then
      local dx, dy = m.x - p.x, m.y - p.y
      if dx * dx + dy * dy < maxD * maxD then cands[#cands + 1] = m end
    end
  end
  if #cands == 0 then return nil end
  if not crowd then return cands[random(#cands)] end
  local best, bestN = nil, -1
  for _ = 1, min(6, #cands) do
    local m = cands[random(#cands)]
    local n = 0
    forNear(m.x, m.y, 1, function(o)
      local dx, dy = o.x - m.x, o.y - m.y
      if dx * dx + dy * dy < 900 then n = n + 1 end
    end)
    if n > bestN then best, bestN = m, n end
  end
  return best
end

---------------------------------------------------------------------- combat core
local C = {}   -- combat functions (kept in a table to stay under Lua's local limit)

-- multiplier applied to everything the player deals
function C.runMult()
  local m = stats.dmg
  if stats.bloodpact > 0 then m = m * (1 + stats.bloodpact * max(0, p.maxHp - p.hp)) end
  if p.retalT > 0 then m = m * (1 + stats.retal) end
  if stats.bulwark > 0 then m = m * (1 + stats.bulwark * p.maxHp) end
  return m
end

function C.damageMob(m, dmg, kx, ky, raw, src)
  if m.dead then return end
  if not raw then
    dmg = dmg * R.mult * (1 - R.res)
    if (m.shockT or 0) > 0 then dmg = dmg * (1.25 + stats.conductor) end
    if (m.burnT or 0) > 0 and stats.pyro > 0 then dmg = dmg * (1 + stats.pyro) end
    if ((m.frozenT or 0) > 0 or (m.chillT or 0) > 0) and stats.permafrost > 0 then dmg = dmg * (1 + stats.permafrost) end
    if stats.lifesteal > 0 then p.hp = min(p.maxHp, p.hp + dmg * stats.lifesteal) end
  end
  if src or not raw then
    -- damage stats: per source, DPS, floating numbers (overkill not counted)
    local applied = min(dmg, max(0, m.hp))
    src = src or "other"
    R.dmgSrc[src] = (R.dmgSrc[src] or 0) + applied
    R.dmgTick = R.dmgTick + applied
    m.numAcc = (m.numAcc or 0) + dmg
  end
  m.hp = m.hp - dmg
  m.flash = 2
  if kx and not m.def.heavy then
    local l = sqrt(kx * kx + ky * ky)
    if l > 0 then
      m.x = m.x + kx / l * 2.5
      m.y = m.y + ky / l * 2.5
    end
  end
  if m.hp <= 0 then C.killMob(m) end
end

function C.burn(m, power)
  m.burnT = 60
  m.burnP = max(m.burnP or 0, power * stats.burn)
end

-- o: { player = true, hurts = true, depth = n, small = true, fire = true, raw = true }
function C.explode(x, y, rad, dmg, o)
  o = o or {}
  if o.player then
    rad = rad * stats.area
    dmg = dmg * stats.aoedmg * stats.boom
  end
  local r2pad = rad
  for _, m in ipairs(mobs) do
    if not m.dead then
      local dx, dy = m.x - x, (m.y - 6) - y
      local rr = r2pad + m.def.r
      if dx * dx + dy * dy <= rr * rr then
        if dmg > 0 then C.damageMob(m, dmg, nil, nil, not o.player, o.player and (o.src or "explosions") or nil) end
        if o.fire and not m.dead then C.burn(m, dmg * 0.15) end
      end
    end
  end
  if o.hurts then
    local dx, dy = p.x - x, (p.y - 6) - y
    if dx * dx + dy * dy <= rad * rad then C.hurtPlayer(3 * mobDmg(secs())) end
  end
  local cols = { S.O, S.Y, S.R, S.W }
  local n = o.small and 5 or floor(10 + rad)
  for _ = 1, n do
    local a = random() * 2 * pi
    local v = rad / 7 * (0.5 + random())
    addPart(x, y, cos(a) * v, sin(a) * v, random(4, 9), cols[random(4)])
  end
  if not o.small then UI.shake = max(UI.shake, 3) end
  sfx("boom")

  if o.player and not o.small then
    -- napalm: burning ground
    if stats.napalm > 0 and #fires < 14 then
      fires[#fires + 1] = { x = x, y = y, r = rad * 0.8, t = 60, dmg = 2 * stats.napalm }
    end
    -- shrapnel
    local n2 = floor(stats.shrapnel + 0.5)
    for i = 1, n2 do
      local a = i / n2 * 2 * pi + random() * 0.4
      bullets[#bullets + 1] = { x = x, y = y, vx = cos(a) * 5, vy = sin(a) * 5, life = 9, dmg = dmg * 0.3,
        pierce = 0, ric = 0, hit = {}, col = S.O, frag = true, src = "shrapnel" }
    end
    -- chain reaction
    local depth = o.depth or 0
    if stats.chainreact > 0 and depth < 3 and random() < stats.chainreact then
      local t = nearestMob(x + random(-40, 40), y + random(-30, 30), 70)
      if t then
        if #strikes < 40 then strikes[#strikes + 1] = { x = t.x, y = t.y - 6, t = 6, rad = rad / stats.area, dmg = dmg / (stats.aoedmg * stats.boom),
          depth = depth + 1, kind = "chain" } end
      end
    end
  end
end

function C.thornBlast(mult)
  local power = stats.thorns * (8 + 12 * stats.armor) * mult
  if power <= 0 then return end
  C.explode(p.x, p.y - 6, 30, power, { player = true, small = true, src = "thorns" })
  ring(p.x, p.y - 6, 30, 18, S.A, 2.5)
end

function C.hurtPlayer(dmg)
  if p.iframes > 0 or state ~= "play" then return end
  -- energy shield
  if stats.shield >= 1 and p.shieldT >= C.shieldCd() then
    p.shieldT = 0
    p.iframes = 10
    ring(p.x, p.y - 6, 12, 14, S.C, 1.5)
    sfx("shield")
    return
  end
  if random() < stats.dodge then
    p.iframes = 8
    addPart(p.x, p.y - 16, 0, -0.5, 10, S.C)
    return
  end
  dmg = dmg * (1 - I.armorReduction(stats.armor))
  p.hp = p.hp - dmg
  p.iframes = floor(18 * stats.iframes)
  if stats.retal > 0 then p.retalT = 60 end
  if dmg >= 2 then UI.shake = max(UI.shake, 2) end
  burst(p.x, p.y - 7, 6, S.R, 1.2)
  sfx("hurt")
  if stats.thorns > 0 then C.thornBlast(1) end
  if p.hp <= 0 then
    if p.revUsed < floor(stats.revive + 0.5) then
      p.revUsed = p.revUsed + 1
      p.hp = p.maxHp * 0.5
      p.iframes = 50
      C.explode(p.x, p.y - 6, 60, 0, { player = true })
      say("SECOND WIND!", 60, S.Y)
    else
      p.hp = 0
      C.gameOver()
    end
  end
end

function C.shieldCd()
  return floor(240 / (1 + 0.5 * (floor(stats.shield + 0.5) - 1)))
end

function C.dropGem(x, y, v)
  if #gems >= 220 then
    local g = gems[random(#gems)]
    g.v = g.v + v
    return
  end
  gems[#gems + 1] = { x = x + random(-2, 2), y = y + random(-2, 2), v = v }
end

function C.killMob(m)
  if m.dead then return end
  m.dead = true
  if m.numAcc and m.numAcc > 0 and UI.showNums and #R.nums < 60 then
    R.nums[#R.nums + 1] = { x = m.x, y = m.y - (m.def.r * 2 + 10), v = m.numAcc, crit = m.numCrit, life = 16 }
    m.numAcc = 0
  end
  R.kills = R.kills + 1
  R.score = R.score + m.def.score * (m.elite and 3 or 1)
  C.dropGem(m.x, m.y - 4, m.def.xp * (1 + secs() / 400) * (m.elite and 4 or 1))
  burst(m.x, m.y - 6, 8, DEATH_COL[m.kind] or S.R, 1.4)
  burst(m.x, m.y - 6, 4, S.R, 0.8)
  sfx("kill")
  if m.def.static and m.outpost then
    m.outpost.state = "cleared"
    R.nestsCleared = R.nestsCleared + 1
    if random() < 0.35 then pickups[#pickups + 1] = { x = m.x, y = m.y + 10, kind = "chest", ttl = 99999 } end
    pickups[#pickups + 1] = { x = m.x - 10, y = m.y + 8, kind = "heart", ttl = 60 * TPS }
    say("Nest destroyed!", 60, S.g)
    C.explode(m.x, m.y - 6, 26, 0, {})
  end
  if m.def.boss then
    R.bossKills = R.bossKills + 1
    for i = 1, floor(stats.bosschests + 0.5) do
      pickups[#pickups + 1] = { x = m.x + (i - 1) * 14, y = m.y, kind = "chest", ttl = 99999 }
    end
    for _ = 1, 3 do
      pickups[#pickups + 1] = { x = m.x + random(-14, 14), y = m.y + random(-10, 10), kind = "heart", ttl = 60 * TPS }
    end
    say("BOSS DOWN!  Grab the chest", 90, S.Y)
    R.boss = nil
    C.explode(m.x, m.y - 10, 30, 0, {})
  else
    local r = random()
    if r < 0.025 * stats.drops then
      pickups[#pickups + 1] = { x = m.x, y = m.y, kind = "heart", ttl = 30 * TPS }
    elseif r < 0.032 * stats.drops then
      pickups[#pickups + 1] = { x = m.x, y = m.y, kind = "magnet", ttl = 30 * TPS }
    end
  end
  if m.def.bomb and not m.exploded then
    m.exploded = true
    if #R.boomQ < 60 then R.boomQ[#R.boomQ + 1] = { m.x, m.y - 6, 26, 25, false } end
  elseif stats.corpse > 0 and random() < stats.corpse and #R.boomQ < 60 then
    R.boomQ[#R.boomQ + 1] = { m.x, m.y - 6, 18, m.def.hp * 2 + 6, true }
  end
end

function C.spawnMob(kind, x, y)
  local d = MOBS[kind]
  local s = secs()
  local m = {
    kind = kind, def = d, x = x, y = y,
    hp = d.hp * hpMul(s), speed = d.speed * speedMul(s) * (0.9 + random() * 0.2),
    flash = 0, cd = random(30, 70), phase = random(0, 11), flip = false,
  }
  if not d.boss and not d.static and kind ~= "bomb_imp" and random() < eliteChance(s) then
    m.elite = true
    m.hp = m.hp * 4
    m.speed = m.speed * 1.1
  end
  m.maxHp = m.hp
  mobs[#mobs + 1] = m
  return m
end

function C.spawnPos()
  local hx, hy = PW / 2 + 18, PH / 2 + 22
  for _ = 1, 8 do
    local a = random() * 2 * pi
    local ca, sa = cos(a), sin(a)
    local k = max(abs(ca) / hx, abs(sa) / hy)
    local x, y = p.x + ca / k, p.y + sa / k
    local nx, ny = world.pushOut(x, y, 5)
    if nx == x and ny == y then return x, y end
  end
end

function C.pickType(s)
  local opts, total = {}, 0
  for _, kind in ipairs(SPAWN_ORDER) do
    local u = MOBS[kind].unlock
    if s >= u then
      local w = (kind == "zombie") and 10 or min(kind == "ghoul" and 6 or 3.5, 1.5 + (s - u) / 30)
      opts[#opts + 1] = { kind, w }
      total = total + w
    end
  end
  local r = random() * total
  for _, o in ipairs(opts) do
    r = r - o[2]
    if r <= 0 then return o[1] end
  end
  return "zombie"
end

---------------------------------------------------------------------- shooting
function C.fire()
  local w = WEAPONS[p.weapon]
  local proj = w.proj + floor(stats.proj + 0.5)
  local baseA = atan2(p.fy, p.fx)
  local range = w.range * stats.range
  local ox, oy = p.x, p.y - 7

  -- aim assist: snap to the nearest mob within ~27 degrees of facing
  local bestD, bestA = range, nil
  for _, m in ipairs(mobs) do
    if not m.dead then
      local dx, dy = m.x - ox, (m.y - 6) - oy
      local d = sqrt(dx * dx + dy * dy)
      if d < bestD and d > 1 then
        local a = atan2(dy, dx)
        if abs((a - baseA + pi) % (2 * pi) - pi) < 0.47 then bestD, bestA = d, a end
      end
    end
  end
  if bestA then baseA = bestA end

  -- fire rate beyond 1 volley per tick and shots that don't fit under the
  -- bullet cap are not lost: they turn into extra damage on what does fire
  local desired = w.cd / stats.rate
  local over = 1
  if desired < 1 then over = 1 / desired; desired = 1 end
  local shots = max(1, min(proj, 240 - #bullets))
  over = over * proj / shots
  local fan = w.fan * (1 + (proj - w.proj) * 0.2)
  local dmg = w.dmg * stats.gundmg * over
  for i = 1, shots do
    local a = baseA + (random() - 0.5) * w.jitter
    if shots > 1 then a = a - fan / 2 + fan * (i - 1) / (shots - 1) end
    local ca, sa = cos(a), sin(a)
    bullets[#bullets + 1] = {
      x = ox + ca * 6, y = oy + sa * 6, vx = ca * w.speed, vy = sa * w.speed,
      life = floor(range / w.speed), dmg = dmg, pierce = floor(stats.pierce + 0.5),
      ric = floor(stats.ricochet + 0.5), hit = {}, col = w.col, aoe = w.aoe, aoeBase = w.dmg * over,
    }
  end
  addPart(ox + p.fx * 8, oy + p.fy * 8, 0, 0, 2, S.Y)
  p.cd = p.cd + desired
  sfx("shoot")
end

function C.bulletHit(b, m)
  b.hit[m] = true
  local dmg = b.dmg
  local crit = random() < stats.crit
  if crit then
    dmg = dmg * stats.critdmg
    addPart(m.x, m.y - 14, 0, -0.6, 6, S.Y)
  end
  if crit then m.numCrit = true end
  C.damageMob(m, dmg, b.vx, b.vy, false, b.src or "gun")
  sfx("hit")
  if b.frag then return end

  -- explosive rounds
  if stats.exround > 0 and not b.aoe then
    C.explode(b.x, b.y, 10, b.dmg / stats.gundmg * 0.35 * stats.exround, { player = true, small = true, src = "exp. rounds" })
  end

  -- storm coil: chain lightning
  if stats.chain > 0 and random() < stats.chain then
    local from, zapped = m, { [m] = true }
    for _ = 1, 3 do
      local t = nearestMob(from.x, from.y - 6, 60, zapped)
      if not t then break end
      zapped[t] = true
      beams[#beams + 1] = { from.x, from.y - 6, t.x, t.y - 6, 3 }
      if stats.conductor > 0 then t.shockT = 40 end
      C.damageMob(t, dmg * 0.6, nil, nil, false, "lightning")
      from = t
    end
    sfx("zap")
  end

  -- splitter
  if stats.split >= 1 and not b.isSplit and #bullets < 240 then
    local a = atan2(b.vy, b.vx)
    local spd = sqrt(b.vx * b.vx + b.vy * b.vy)
    for k = 1, floor(stats.split + 0.5) * 2 do
      local na = a + ((k % 2 == 0) and 0.6 or -0.6) * (1 + floor((k - 1) / 2) * 0.5)
      bullets[#bullets + 1] = { x = b.x, y = b.y, vx = cos(na) * spd, vy = sin(na) * spd, life = 12, dmg = b.dmg * 0.5,
        pierce = 0, ric = 0, hit = { [m] = true }, col = b.col, isSplit = true }
    end
  end
end

function C.updateBullets()
  for i = #bullets, 1, -1 do
    local b = bullets[i]
    local dead = false
    local steps = max(1, ceil(max(abs(b.vx), abs(b.vy)) / 3))
    for _ = 1, steps do
      b.x = b.x + b.vx / steps
      b.y = b.y + b.vy / steps
      local target
      forNear(b.x, b.y + 6, 1, function(m)
        if not b.hit[m] then
          local dx, dy = m.x - b.x, (m.y - 6) - b.y
          local r = m.def.r + 1
          if dx * dx + dy * dy <= r * r then target = m; return true end
        end
      end)
      if target and b.ally then
        C.damageMob(target, b.dmg * (1 - R.res), b.vx, b.vy, true, "allies")
        dead = true
        break
      end
      if target then
        C.bulletHit(b, target)
        if b.aoe then C.explode(b.x, b.y, b.aoe, b.aoeBase, { player = true, src = "launcher" }); dead = true; break end
        if b.ric > 0 then
          b.ric = b.ric - 1
          local t = nearestMob(b.x, b.y, 90, b.hit)
          if t then
            local dx, dy = t.x - b.x, (t.y - 6) - b.y
            local d = sqrt(dx * dx + dy * dy)
            local spd = sqrt(b.vx * b.vx + b.vy * b.vy)
            b.vx, b.vy = dx / d * spd, dy / d * spd
            b.life = max(b.life, ceil(d / spd) + 2)
            break
          end
        end
        if b.pierce <= 0 then dead = true; break end
        b.pierce = b.pierce - 1
      end
    end
    b.life = b.life - 1
    if b.life <= 0 and not dead then
      dead = true
      if b.aoe then C.explode(b.x, b.y, b.aoe, b.aoeBase, { player = true, src = "launcher" }) end
    end
    if b.aoe and not dead and frame % 2 == 0 then addPart(b.x, b.y, 0, 0, 4, S.D) end
    if dead then removeAt(bullets, i) end
  end
end

---------------------------------------------------------------------- update: player
function C.updatePlayer()
  local ix, iy, ax, ay = 0, 0, 0, 0
  if held[keys.a] then ix = ix - 1 end
  if held[keys.d] then ix = ix + 1 end
  if held[keys.w] then iy = iy - 1 end
  if held[keys.s] then iy = iy + 1 end
  if held[keys.left] then ax = ax - 1 end
  if held[keys.right] then ax = ax + 1 end
  if held[keys.up] then ay = ay - 1 end
  if held[keys.down] then ay = ay + 1 end

  -- clean speeds keep scrolling smooth: 2 px straight, 1.5 px per axis diagonal
  local spd = 2 * stats.speed
  local tx, ty = ix * spd, iy * spd
  if ix ~= 0 and iy ~= 0 then tx, ty = tx * 0.75, ty * 0.75 end
  p.vx = p.vx + (tx - p.vx) * 0.5
  p.vy = p.vy + (ty - p.vy) * 0.5
  if abs(tx - p.vx) < 0.06 then p.vx = tx end
  if abs(ty - p.vy) < 0.06 then p.vy = ty end
  p.x, p.y = C.pushStructures(world.pushOut(p.x + p.vx + p.knx, p.y + p.vy + p.kny, 4))
  p.knx, p.kny = p.knx * 0.7, p.kny * 0.7
  p.moving = (ix ~= 0 or iy ~= 0)

  local shooting = held[keys.space]
  if ax ~= 0 or ay ~= 0 then
    local l = sqrt(ax * ax + ay * ay)
    p.fx, p.fy = ax / l, ay / l
    shooting = true
  elseif p.moving then
    local l = sqrt(ix * ix + iy * iy)
    p.fx, p.fy = ix / l, iy / l
  end
  if p.fx < -0.1 then p.flip = true elseif p.fx > 0.1 then p.flip = false end

  p.cd = max(-1, p.cd - 1)
  if shooting and p.cd <= 0 then C.fire() end
  if p.iframes > 0 then p.iframes = p.iframes - 1 end
  if p.retalT > 0 then p.retalT = p.retalT - 1 end
  if stats.shield >= 1 and p.shieldT < C.shieldCd() then p.shieldT = p.shieldT + 1 end

  if stats.regen > 0.01 and p.hp < p.maxHp then
    p.regenT = p.regenT + stats.regen
    if p.regenT >= 200 then
      p.regenT = 0
      p.hp = min(p.maxHp, p.hp + 1)
      addPart(p.x, p.y - 16, 0, -0.4, 10, S.g)
    end
  end
  if stats.drain > 0 then
    p.drainT = p.drainT + stats.drain
    if p.drainT >= 400 then
      p.drainT = 0
      if p.hp > 1 then p.hp = p.hp - 1; addPart(p.x, p.y - 16, 0, -0.4, 10, S.R) end
    end
  end
end

---------------------------------------------------------------------- update: mobs
function C.updateMobs()
  local s = secs()
  for i = #mobs, 1, -1 do
    local m = mobs[i]
    if m.dead then
      removeAt(mobs, i)
    else
      local d = m.def
      local dx, dy = p.x - m.x, p.y - m.y
      local dist = sqrt(dx * dx + dy * dy)
      if d.static then
        C.updateNest(m, s, dist)
      elseif dist > 460 then
        if d.boss then
          local x, y = C.spawnPos()
          if x then m.x, m.y = x, y end
        else
          removeAt(mobs, i)
        end
      else
        if m.flash > 0 then m.flash = m.flash - 1 end
        m.cd = m.cd - 1
        local nx, ny = 0, 0
        if dist > 0.01 then nx, ny = dx / dist, dy / dist end
        m.flip = dx < 0
        local mv = m.speed

        -- what to walk at: the player, a nearby outpost, or a trapped survivor
        local siege, tdist = nil, dist
        if m.guard and R.survivor == m.guard and dist > 50 then
          local tx, ty = m.guard.x - m.x, m.guard.y - m.y
          tdist = sqrt(tx * tx + ty * ty)
          if tdist > 0.01 then nx, ny = tx / tdist, ty / tdist end
          if tdist < 14 then mv = 0 end
        elseif not d.boss then
          for _, o in ipairs(R.activeOutposts) do
            if o.state == "alive" then
              local ox, oy = o.x - m.x, (o.y - 2) - m.y
              local od = sqrt(ox * ox + oy * oy)
              if od < 170 and od < dist * 0.8 then
                siege, tdist = o, od
                if od > 0.01 then nx, ny = ox / od, oy / od end
                m.flip = ox < 0
              end
            end
          end
        end

        -- status effects
        if m.burnT and m.burnT > 0 then
          m.burnT = m.burnT - 1
          if m.burnT % 10 == 0 then
            C.damageMob(m, m.burnP, nil, nil, false, "burn")
            addPart(m.x + random(-3, 3), m.y - 10, 0, -0.5, 5, (random() < 0.5) and S.O or S.R)
          end
          if m.burnT <= 0 then m.burnP = 0 end
        end
        if m.shockT and m.shockT > 0 then m.shockT = m.shockT - 1 end
        if m.chillT and m.chillT > 0 then m.chillT = m.chillT - 1; mv = mv * 0.5 end
        if m.frozenT and m.frozenT > 0 then m.frozenT = m.frozenT - 1; mv = 0 end

        if d.ranged and not m.dead then
          if dist < 50 then mv = -mv * 0.6 elseif dist < 80 then mv = 0 end
          if dist < 115 and m.cd <= 0 and (m.frozenT or 0) <= 0 then
            m.cd = random(50, 80)
            local sx, sy = m.x, m.y - 8
            local tx, ty = p.x - sx, p.y - 7 - sy
            local l = sqrt(tx * tx + ty * ty)
            eshots[#eshots + 1] = { x = sx, y = sy, vx = tx / l * 2.6, vy = ty / l * 2.6, life = 48, dmg = 1 * mobDmg(s) * (m.elite and 1.5 or 1) }
          end
        end

        if d.bomb and not m.dead then
          if m.fuse then
            m.fuse = m.fuse - 1
            mv = mv * 0.3
            if m.fuse <= 0 then
              m.exploded = true
              C.explode(m.x, m.y - 6, 28, 25, { hurts = true })
              m.fuse = nil
              C.killMob(m)
            end
          elseif dist < 18 then
            m.fuse = 16
          end
        end

        if d.boss and m.cd <= 0 then
          m.cd = 100
          for _ = 1, 3 do C.spawnMob("zombie", m.x + random(-20, 20), m.y + random(-14, 14)) end
        end

        if m.stun and m.stun > 0 then
          m.stun = m.stun - 1
          mv = 0
        end

        if not m.dead then
          m.x = m.x + nx * mv
          m.y = m.y + ny * mv
          if not d.boss then m.x, m.y = C.pushStructures(world.pushOut(m.x, m.y, 3)) end
          m.moving = mv ~= 0

          local r = d.r
          -- separation runs every other tick per mob (halves the cost with big hordes)
          if (frame + m.phase) % 2 == 0 then forNear(m.x, m.y, 1, function(o)
            if o ~= m then
              local ox, oy = m.x - o.x, m.y - o.y
              local rr = r + o.def.r - 2
              local d2 = ox * ox + oy * oy
              if d2 < rr * rr and d2 > 0.0001 then
                local dd = sqrt(d2)
                local push = (rr - dd) * 0.5
                if o.def.boss then push = push * 2 end
                if not d.boss then
                  m.x = m.x + ox / dd * push
                  m.y = m.y + oy / dd * push
                end
              end
            end
          end) end

          if m.atk and m.atk > 0 then m.atk = m.atk - 1 end
          if siege and tdist < d.r + 13 and (m.atk or 0) <= 0 and not d.bomb then
            siege.hp = siege.hp - d.dmg * mobDmg(s) * (m.elite and 1.5 or 1)
            m.atk = 20
            addPart(siege.x + random(-6, 6), siege.y - 8, 0, -0.4, 5, S.R)
          end
          if not d.bomb and dist < r + 5 and (m.atk or 0) <= 0 and (m.frozenT or 0) <= 0 then
            local before = p.hp
            C.hurtPlayer(d.dmg * mobDmg(s) * (m.elite and 1.5 or 1))
            if p.hp < before then
              m.atk = d.heavy and 40 or 20
              if d.heavy then
                m.stun = 25
                p.knx, p.kny = -nx * 4, -ny * 4
              end
            end
          end
        end
      end
    end
  end
end

function C.updateEShots()
  for i = #eshots, 1, -1 do
    local e = eshots[i]
    e.x, e.y = e.x + e.vx, e.y + e.vy
    e.life = e.life - 1
    local dx, dy = p.x - e.x, (p.y - 7) - e.y
    if dx * dx + dy * dy < 36 then
      C.hurtPlayer(e.dmg)
      removeAt(eshots, i)
    elseif e.life <= 0 then
      removeAt(eshots, i)
    end
  end
end

---------------------------------------------------------------------- passives + spells
function C.sawPositions()
  local list = {}
  local n = floor(stats.saws + 0.5)
  for i = 1, n do
    local a = p.sawA + (i - 1) * 2 * pi / n
    list[i] = { p.x + cos(a) * 26, p.y - 6 + sin(a) * 26, a }
  end
  return list
end

function C.fireRingRadius() return (16 + 6 * stats.firering) * stats.area end

function C.updatePassives()
  local sp = R.spell
  local aoe = stats.aoedmg

  if stats.saws >= 1 then
    p.sawA = p.sawA + 0.18
    for _, s in ipairs(C.sawPositions()) do
      forNear(s[1], s[2] + 6, 1, function(m)
        local dx, dy = m.x - s[1], (m.y - 6) - s[2]
        local r = m.def.r + 3
        if dx * dx + dy * dy <= r * r and (m.sawCd or 0) <= frame then
          m.sawCd = frame + 8
          C.damageMob(m, 5 * stats.sawdmg, cos(s[3]), sin(s[3]), false, "saws")
        end
      end)
    end
  end

  if stats.aura >= 1 then
    p.auraT = p.auraT + 1
    if p.auraFlash > 0 then p.auraFlash = p.auraFlash - 1 end
    if p.auraT >= 12 then
      p.auraT = 0
      p.auraFlash = 3
      local rad = (20 + stats.aura * 8) * stats.area
      local dmg = (2 + stats.aura * 1.5) * aoe
      for _, m in ipairs(mobs) do
        if not m.dead then
          local dx, dy = m.x - p.x, m.y - p.y
          if dx * dx + dy * dy <= (rad + m.def.r) ^ 2 then C.damageMob(m, dmg, nil, nil, false, "aura") end
        end
      end
    end
  end

  -- fire ring: constant burn around you
  if stats.firering >= 1 then
    sp.ring = sp.ring + 1
    if sp.ring >= 6 then
      sp.ring = 0
      local rad = C.fireRingRadius()
      local dmg = (1 + 0.6 * stats.firering) * aoe * stats.fireringdmg
      for _, m in ipairs(mobs) do
        if not m.dead then
          local dx, dy = m.x - p.x, (m.y - 6) - (p.y - 6)
          if dx * dx + dy * dy <= (rad + m.def.r) ^ 2 then
            C.damageMob(m, dmg, nil, nil, false, "fire ring")
            if not m.dead then C.burn(m, 0.5 * stats.firering * aoe) end
          end
        end
      end
    end
  end

  -- meteor: hits the biggest crowd
  if stats.meteor >= 1 then
    sp.meteor = sp.meteor + 1
    if sp.meteor >= max(10, floor(80 * stats.cdr)) then
      sp.meteor = 0
      for _ = 1, floor(stats.meteor + 0.5) do
        local t = pickTarget(170, true)
        if t then
          strikes[#strikes + 1] = { x = t.x + random(-6, 6), y = t.y - 6 + random(-4, 4), t = 20 + random(0, 8), rad = 26,
            dmg = 18 * stats.meteordmg, kind = "meteor", fire = true }
        end
      end
    end
  end

  -- frost nova
  if stats.frost >= 1 then
    sp.frost = sp.frost + 1
    if sp.frost >= max(20, floor(120 * stats.cdr * stats.frostcd)) then
      sp.frost = 0
      local lvl = stats.frost
      local rad = (40 + 10 * (lvl - 1)) * stats.area
      local dmg = 5 * lvl * aoe
      for _, m in ipairs(mobs) do
        if not m.dead then
          local dx, dy = m.x - p.x, m.y - p.y
          if dx * dx + dy * dy <= (rad + m.def.r) ^ 2 then
            m.frozenT = m.def.boss and 15 or 40
            m.chillT = 100
            C.damageMob(m, dmg, nil, nil, false, "frost nova")
          end
        end
      end
      ring(p.x, p.y - 6, rad, 36, S.C, rad / 8)
      ring(p.x, p.y - 6, rad * 0.6, 20, S.W, rad / 12)
      sfx("frost")
    end
  end

  -- thunderstorm
  if stats.thunder >= 1 then
    sp.thunder = sp.thunder + 1
    if sp.thunder >= max(4, floor(30 / stats.thunder * stats.cdr)) then
      sp.thunder = 0
      local t = pickTarget(170, false)
      if t then
        beams[#beams + 1] = { t.x + random(-20, 20), t.y - 120, t.x, t.y - 6, 3, bolt = true }
        t.shockT = 40
        C.damageMob(t, 12 * aoe, nil, nil, false, "thunder")
        burst(t.x, t.y - 6, 5, S.Y, 1.2)
        sfx("zap")
      end
    end
  end

  -- arcane orbs
  if stats.orbs >= 1 then
    sp.orbs = sp.orbs + 1
    if sp.orbs >= max(5, floor(20 * stats.cdr)) then
      sp.orbs = 0
      for k = 1, floor(stats.orbs + 0.5) do
        local a = random() * 2 * pi
        orbs[#orbs + 1] = { x = p.x + cos(a) * 6, y = p.y - 8 + sin(a) * 6, vx = cos(a) * 2, vy = sin(a) * 2, life = 70, dmg = 7 * aoe }
      end
    end
  end

  -- mortar
  if stats.mortar >= 1 then
    sp.mortar = sp.mortar + 1
    if sp.mortar >= 40 then
      sp.mortar = 0
      for _ = 1, floor(stats.mortar + 0.5) do
        local t = pickTarget(150, false)
        if t then
          strikes[#strikes + 1] = { x = t.x, y = t.y - 6, t = 15, rad = 20, dmg = 12, kind = "mortar" }
        end
      end
    end
  end

  -- iron maiden: automatic thorns
  if stats.thornpulse >= 1 then
    p.thornT = p.thornT + 1
    if p.thornT >= 40 then
      p.thornT = 0
      C.thornBlast(0.6)
    end
  end
end

function C.updateSpellObjects()
  -- falling strikes (meteor, mortar, chain reaction)
  for i = #strikes, 1, -1 do
    local s = strikes[i]
    s.t = s.t - 1
    if s.t <= 0 then
      removeAt(strikes, i)
      C.explode(s.x, s.y, s.rad, s.dmg, { player = true, depth = s.depth, fire = s.fire,
        src = (s.kind == "chain") and "chain reaction" or s.kind })
    end
  end
  -- burning ground
  for i = #fires, 1, -1 do
    local f = fires[i]
    f.t = f.t - 1
    if f.t % 10 == 0 then
      for _, m in ipairs(mobs) do
        if not m.dead then
          local dx, dy = m.x - f.x, (m.y - 6) - f.y
          if dx * dx + dy * dy <= f.r * f.r then
            C.damageMob(m, f.dmg * stats.aoedmg, nil, nil, false, "napalm")
            if not m.dead then C.burn(m, 0.4 * stats.aoedmg) end
          end
        end
      end
    end
    if f.t <= 0 then removeAt(fires, i) end
  end
  -- homing orbs
  for i = #orbs, 1, -1 do
    local o = orbs[i]
    if not o.target or o.target.dead or frame % 6 == 0 then o.target = nearestMob(o.x, o.y, 130) end
    if o.target then
      local dx, dy = o.target.x - o.x, (o.target.y - 6) - o.y
      local d = sqrt(dx * dx + dy * dy)
      if d > 0.1 then
        o.vx = o.vx * 0.82 + dx / d * 0.9
        o.vy = o.vy * 0.82 + dy / d * 0.9
      end
      if d < o.target.def.r + 2 then
        C.damageMob(o.target, o.dmg, nil, nil, false, "orbs")
        burst(o.x, o.y, 3, S.C, 0.8)
        o.life = 0
      end
    end
    o.x, o.y = o.x + o.vx, o.y + o.vy
    o.life = o.life - 1
    if o.life <= 0 then removeAt(orbs, i) end
  end
end

---------------------------------------------------------------------- update: pickups / spawns
function C.updatePickups()
  local mag = stats.magnet
  for i = #gems, 1, -1 do
    local g = gems[i]
    local dx, dy = p.x - g.x, (p.y - 6) - g.y
    local d = sqrt(dx * dx + dy * dy)
    if d < 7 then
      p.xp = p.xp + g.v * stats.xp
      removeAt(gems, i)
      sfx("xp")
    elseif g.pull or d < mag then
      g.pull = true
      local sp = max(4, 2 * stats.speed + 1.5)
      g.x, g.y = g.x + dx / d * sp, g.y + dy / d * sp
    elseif d > 500 then
      removeAt(gems, i)
    end
  end

  for i = #pickups, 1, -1 do
    local it = pickups[i]
    it.ttl = it.ttl - 1
    local dx, dy = p.x - it.x, p.y - it.y
    if dx * dx + dy * dy < 100 then
      removeAt(pickups, i)
      if it.kind == "heart" then
        p.hp = min(p.maxHp, p.hp + 3)
        say("+30 HP", 25, S.R)
        sfx("pick")
      elseif it.kind == "magnet" then
        for _, g in ipairs(gems) do g.pull = true end
        say("MAGNET! All XP incoming", 40, S.C)
        sfx("pick")
      elseif it.kind == "chest" then
        C.startPick("chest")
      end
    elseif it.ttl <= 0 then
      removeAt(pickups, i)
    end
  end

  while p.xp >= p.xpNext do
    p.xp = p.xp - p.xpNext
    p.level = p.level + 1
    p.xpNext = xpFor(p.level)
    p.pending = p.pending + 1
  end
end

function C.updateSpawns()
  local s = secs()
  for _, kind in ipairs(SPAWN_ORDER) do
    if not R.announced[kind] and s >= MOBS[kind].unlock then
      R.announced[kind] = true
      say(MOBS[kind].intro, 80, S.O)
    end
  end

  R.spawnTimer = R.spawnTimer - 1
  if R.spawnTimer <= 0 then
    R.spawnTimer = max(5, floor((34 - s / 10) / stats.spawn))
    local batch = 1 + floor(s / 90)
    for _ = 1, batch do
      if #mobs < mobCap(s) then
        local x, y = C.spawnPos()
        if x then C.spawnMob(C.pickType(s), x, y) end
      end
    end
  end

  if R.tick >= R.nextHorde then
    R.nextHorde = R.nextHorde + 60 * TPS
    say("A HORDE APPROACHES!", 70, S.R)
    for _ = 1, 16 + floor(s / 30) * 2 do
      if #mobs < mobCap(s) + 40 then
        local x, y = C.spawnPos()
        if x then C.spawnMob((s >= 40 and random() < 0.35) and "ghoul" or "zombie", x, y) end
      end
    end
  end

  if R.tick >= R.nextSwarm then
    R.nextSwarm = R.nextSwarm + 120 * TPS
    say("SWARM!", 70, S.R)
    for _ = 1, 30 + floor(s / 60) * 3 do
      if #mobs < mobCap(s) + 60 then
        local x, y = C.spawnPos()
        if x then C.spawnMob((random() < 0.5) and "ghoul" or "zombie", x, y) end
      end
    end
  end

  if R.tick >= R.nextBoss then
    R.nextBoss = R.nextBoss + 180 * TPS
    local x, y = C.spawnPos()
    if x then
      R.boss = C.spawnMob("boss", x, y)
      say("!!! THE GRAVE KING RISES !!!", 100, S.R)
      sfx("boss")
    end
  end
end

function C.updateFx()
  for i = #parts, 1, -1 do
    local q = parts[i]
    q.x, q.y = q.x + q.vx, q.y + q.vy
    q.vx, q.vy = q.vx * 0.85, q.vy * 0.85
    q.life = q.life - 1
    if q.life <= 0 then removeAt(parts, i) end
  end
  for i = #beams, 1, -1 do
    local b = beams[i]
    b[5] = b[5] - 1
    if b[5] <= 0 then removeAt(beams, i) end
  end
  if UI.shake > 0 then UI.shake = UI.shake - 1 end
  if UI.msgTimer > 0 then UI.msgTimer = UI.msgTimer - 1 end
end

---------------------------------------------------------------------- level-up / chest / death
function C.offerCount() return max(3, min(4, floor(stats.choices + 0.5))) end

function C.startPick(kind)
  R.offerKind = kind
  R.banishMode = false
  R.offers = I.roll(owned, stats.luck, C.offerCount(), kind == "chest" and "epic" or nil, R.banned)
  state = "pick"
  sfx("level")
end

function C.pickTitle()
  if R.offerKind == "chest" then return "TREASURE!  Pick a reward" end
  if R.offerKind == "bonus" then return "HEAD START  -  free pick" end
  return "LEVEL UP!  Level " .. (p.level - p.pending + 1)
end

function C.nextPickOrPlay()
  if p.bonus > 0 then C.startPick("bonus")
  elseif p.pending > 0 then C.startPick("level")
  else
    R.offers = nil
    state = "play"
    p.iframes = max(p.iframes, 20)
  end
end

function C.choose(i)
  local it = R.offers and R.offers[i]
  if not it then return end
  if R.banishMode then
    if it.id == "snack" then return end
    R.banned[it.id] = true
    R.banishes = R.banishes - 1
    R.banishMode = false
    local exclude = {}
    for _, o in ipairs(R.offers) do exclude[o.id] = true end
    R.offers[i] = I.roll(owned, stats.luck, 1, R.offerKind == "chest" and "epic" or nil, R.banned, exclude)[1]
    say(it.name .. " banished", 30, S.A)
    return
  end
  giveItem(it.id)
  if it.weapon then p.weapon = it.weapon end
  recompute()
  if it.heal then p.hp = min(p.maxHp, p.hp + it.heal) end
  say(it.name .. "!", 40, P.slot[I.RARITY[it.rarity].col])
  if R.offerKind == "level" then p.pending = p.pending - 1
  elseif R.offerKind == "bonus" then p.bonus = p.bonus - 1 end
  C.nextPickOrPlay()
end

function C.gameOver()
  state = "dead"
  R.deadTimer = 0
  local mins = secs() / 60
  local souls = (R.kills / 10 + 5 * mins + 25 * R.bossKills) * stats.souls * Tree.prestigeSouls(prof.prestige)
  R.soulsEarned = floor(souls)
  prof.souls = prof.souls + R.soulsEarned
  prof.soulsTotal = (prof.soulsTotal or 0) + R.soulsEarned
  prof.runs = prof.runs + 1
  prof.kills = (prof.kills or 0) + R.kills
  prof.bosses = (prof.bosses or 0) + R.bossKills
  if R.score > prof.best then prof.best = R.score; R.newBest = true end
  if secs() > prof.bestTime then prof.bestTime = floor(secs()) end
  Prof.save(prof)
  UI.board = Prof.leaderboard(10)
end

---------------------------------------------------------------------- outposts, nests, survivors, followers
local SOLDIER_POS = { { -20, 4 }, { 2, 14 } }           -- soldier feet, relative to the camp centre
local STRUCT_ALIVE = { { 0, -3, 8 }, { 32, -1, 8 } }    -- tent + MG nest block movement
local STRUCT_RUIN = { { 0, -3, 7 } }
local FOLLOW_SLOT = { { -16, 6 }, { 16, 8 } }
local OUT_TMP = {}

function C.pushStructures(x, y, r)
  r = r or 4
  for _, o in ipairs(R.activeOutposts) do
    if o.state ~= "cleared" then
      for _, c in ipairs(o.state == "alive" and STRUCT_ALIVE or STRUCT_RUIN) do
        local cx, cy, cr = o.x + c[1], o.y + c[2], c[3] + r
        local dx, dy = x - cx, y - cy
        local d2 = dx * dx + dy * dy
        if d2 < cr * cr then
          local d = sqrt(d2)
          if d < 0.01 then dx, dy, d = 1, 0, 1 end
          x, y = cx + dx / d * cr, cy + dy / d * cr
        end
      end
    end
  end
  return x, y
end

function C.allyShot(x, y, t, dmg, jitter)
  if #bullets >= 260 then return end
  local a = atan2((t.y - 6) - y, t.x - x) + (random() - 0.5) * jitter
  local ca, sa = cos(a), sin(a)
  bullets[#bullets + 1] = { x = x + ca * 4, y = y + sa * 4, vx = ca * 6, vy = sa * 6, life = 26, dmg = dmg,
    pierce = 0, ric = 0, hit = {}, col = S.Y, ally = true }
end

function C.updateNest(m, s, dist)
  if m.flash > 0 then m.flash = m.flash - 1 end
  m.cd = m.cd - 1
  if m.cd <= 0 and dist < 400 then
    m.cd = 140
    for _ = 1, 2 do
      if #mobs < mobCap(s) + 20 then
        C.spawnMob((random() < 0.4) and "ghoul" or "zombie", m.x + random(-16, 16), m.y + random(8, 16))
      end
    end
    burst(m.x, m.y - 6, 5, S.Z, 1)
  end
end

local OUTPOST_TIME = 300   -- outposts only show up from minute 5

function C.updateOutposts(s)
  if s < OUTPOST_TIME then return end
  if not R.outpostsAnnounced then
    R.outpostsAnnounced = true
    say("Survivor outposts spotted - follow the flags!", 80, S.C)
  end
  if R.tick % 10 == 1 then
    local n = world.outpostsNear(p.x, p.y, 340, OUT_TMP)
    local act = {}
    for i = 1, n do
      local site = OUT_TMP[i]
      local o = R.outposts[site.key]
      -- a camp is only "found" while it's off-screen, so none pop in under your feet
      local dx, dy = site.x - p.x, site.y - p.y
      if not o and dx * dx + dy * dy > 230 * 230 then
        local mh = 80 * (1 + 0.2 * s / 60)
        o = { x = site.x, y = site.y, hp = mh, maxHp = mh, state = "alive", cd = { 0, 7, 0 }, flip = { false, false, false } }
        R.outposts[site.key] = o
      end
      if o then act[#act + 1] = o end
    end
    R.activeOutposts = act
  end
  local sc = allyScale(s)
  for _, o in ipairs(R.activeOutposts) do
    if o.state == "alive" then
      for k, sp in ipairs(SOLDIER_POS) do
        if o.hp > o.maxHp * (k - 1) / 2.5 then
          o.cd[k] = o.cd[k] - 1
          if o.cd[k] <= 0 then
            local sx, sy = o.x + sp[1], o.y + sp[2] - 8
            local t = nearestMob(sx, sy, 130)
            if t then
              o.cd[k] = 14
              C.allyShot(sx, sy, t, 5 * sc, 0.06)
              o.flip[k] = t.x < sx
            end
          end
        end
      end
      if o.hp > o.maxHp * 0.3 then
        o.cd[3] = o.cd[3] - 1
        if o.cd[3] <= 0 then
          local gx, gy = o.x + 40, o.y - 5
          local t = nearestMob(gx, gy, 150)
          if t then
            o.cd[3] = 3
            C.allyShot(gx, gy, t, 2.2 * sc, 0.15)
            o.flip[3] = t.x < gx
          end
        end
      end
      if not o.warned and o.hp < o.maxHp * 0.5 then
        o.warned = true
        say("An outpost is under attack!", 50, S.O)
      end
      if o.hp <= 0 then
        o.state = "nest"
        local m = C.spawnMob("nest", o.x + 4, o.y + 4)
        m.outpost = o
        say("Outpost overrun - it's infested!", 70, S.R)
        burst(o.x, o.y - 6, 14, S.Z, 2)
      end
    end
  end
end

function C.updateSurvivor(s)
  local sv = R.survivor
  if not sv then
    if R.tick >= R.nextSurvivor and #R.followers < 2 then
      R.nextSurvivor = R.tick + random(75, 110) * TPS
      for _ = 1, 10 do
        local a = random() * 2 * pi
        local x, y = p.x + cos(a) * 140, p.y + sin(a) * 100
        local nx, ny = C.pushStructures(world.pushOut(x, y, 6))
        if nx == x and ny == y then
          sv = { x = x, y = y, hp = 10, ttl = 45 * TPS, hurtCd = 0 }
          R.survivor = sv
          local n = 4 + floor(s / 60)
          for k = 1, n do
            local b = k / n * 2 * pi
            local m = C.spawnMob((s > 60 and random() < 0.3) and "ghoul" or "zombie", x + cos(b) * 26, y + sin(b) * 20)
            m.guard = sv
          end
          say("A survivor needs help!  Look for the  !", 70, S.Y)
          break
        end
      end
    end
    return
  end
  sv.ttl = sv.ttl - 1
  if sv.hurtCd > 0 then sv.hurtCd = sv.hurtCd - 1 end
  local threatened = false
  forNear(sv.x, sv.y, 1, function(m)
    local dx, dy = m.x - sv.x, m.y - sv.y
    local d2 = dx * dx + dy * dy
    if d2 < 900 then threatened = true end
    if d2 < (m.def.r + 6) ^ 2 and sv.hurtCd <= 0 and not m.def.static then
      sv.hp = sv.hp - mobDmg(s)
      sv.hurtCd = 20
      addPart(sv.x, sv.y - 8, 0, -0.5, 6, S.R)
    end
  end)
  local pdx, pdy = p.x - sv.x, p.y - sv.y
  if not threatened and pdx * pdx + pdy * pdy < 30 * 30 then
    local mh = floor(12 * (1 + 0.1 * s / 60))
    R.followers[#R.followers + 1] = { x = sv.x, y = sv.y, hp = mh, maxHp = mh, cd = 0, flip = false, hurtCd = 0, regen = 0 }
    R.rescued = R.rescued + 1
    R.survivor = nil
    say(("Survivor rescued!  (%d/2 followers)"):format(#R.followers), 60, S.g)
    sfx("pick")
  elseif sv.hp <= 0 or sv.ttl <= 0 then
    R.survivor = nil
    R.nextSurvivor = R.tick + 60 * TPS
    say("The survivor didn't make it...", 50, S.A)
    burst(sv.x, sv.y - 6, 8, S.R, 1.2)
  end
end

function C.updateFollowers(s)
  local sc = allyScale(s)
  for i = #R.followers, 1, -1 do
    local f = R.followers[i]
    local slot = FOLLOW_SLOT[i] or FOLLOW_SLOT[1]
    local tx, ty = p.x + slot[1] - f.x, p.y + slot[2] - f.y
    local d = sqrt(tx * tx + ty * ty)
    if d > 200 then
      f.x, f.y = p.x + slot[1], p.y + slot[2]
    elseif d > 3 then
      local sp = min(d * 0.25, 2.4 * stats.speed)
      f.x, f.y = C.pushStructures(world.pushOut(f.x + tx / d * sp, f.y + ty / d * sp, 4))
    end
    f.moving = d > 3
    f.cd = f.cd - 1
    if f.cd <= 0 then
      local t = nearestMob(f.x, f.y - 7, 120)
      if t then
        f.cd = 10
        C.allyShot(f.x, f.y - 7, t, 4 * sc, 0.08)
        f.flip = t.x < f.x
      end
    end
    if f.hurtCd > 0 then f.hurtCd = f.hurtCd - 1 end
    forNear(f.x, f.y, 1, function(m)
      if f.hurtCd <= 0 and not m.def.static and m.def.dmg > 0 then
        local dx, dy = m.x - f.x, m.y - f.y
        if dx * dx + dy * dy < (m.def.r + 5) ^ 2 then
          f.hp = f.hp - m.def.dmg * mobDmg(s)
          f.hurtCd = 20
        end
      end
    end)
    f.regen = f.regen + 1
    if f.regen >= 100 then f.regen = 0; f.hp = min(f.maxHp, f.hp + 1) end
    if f.hp <= 0 then
      table.remove(R.followers, i)
      say("A follower has fallen", 50, S.R)
      burst(f.x, f.y - 6, 10, S.R, 1.4)
    end
  end
end

-- rolling 3-second DPS and floating damage numbers (summed per mob every half second)
function C.updateDamageStats()
  local slot = R.tick % 60 + 1
  R.dmgSum = R.dmgSum - (R.dmgHist[slot] or 0) + R.dmgTick
  R.dmgHist[slot] = R.dmgTick
  R.dmgTick = 0
  R.dps = R.dmgSum / 3
  for _, m in ipairs(mobs) do
    if m.numAcc and m.numAcc > 0 and (m.dead or (R.tick + m.phase) % 10 == 0) then
      if UI.showNums and #R.nums < 60 then
        R.nums[#R.nums + 1] = { x = m.x, y = m.y - (m.def.r * 2 + 10), v = m.numAcc, crit = m.numCrit, life = 16 }
      end
      m.numAcc, m.numCrit = 0, nil
    end
  end
  for i = #R.nums, 1, -1 do
    local n = R.nums[i]
    n.life = n.life - 1
    n.y = n.y - 0.4
    if n.life <= 0 then removeAt(R.nums, i) end
  end
end

local function update()
  R.tick = R.tick + 1
  C.updateDamageStats()
  R.mult = C.runMult()
  R.res = mobRes(secs())
  if #R.boomQ > 0 then
    local q = R.boomQ
    R.boomQ = {}
    for i = 1, #q do
      local b = q[i]
      if i <= 25 then C.explode(b[1], b[2], b[3], b[4], { player = b[5], src = b[5] and "corpse bomb" or nil })
      elseif #R.boomQ < 60 then R.boomQ[#R.boomQ + 1] = b end
    end
  end
  buildGrid()
  C.updatePlayer()
  C.updateBullets()
  C.updateMobs()
  C.updateEShots()
  C.updatePassives()
  C.updateSpellObjects()
  C.updatePickups()
  C.updateSpawns()
  C.updateOutposts(secs())
  C.updateSurvivor(secs())
  C.updateFollowers(secs())
  C.updateFx()
  if state == "play" and (p.pending > 0 or p.bonus > 0) then C.nextPickOrPlay() end
end

---------------------------------------------------------------------- skill tree actions
local TR = {}

function TR.buy()
  local n = Tree.byId[UI.treeSel]
  local lvl = prof.tree[n.id] or 0
  if lvl >= n.max then say("Already maxed", 30, S.A); return end
  if not Tree.unlocked(n, prof.tree) then say("Locked - buy the node before it first", 40, S.R); return end
  local cost = Tree.cost(n, lvl + 1)
  if prof.souls < cost then say("Not enough souls", 30, S.R); return end
  prof.souls = prof.souls - cost
  prof.tree[n.id] = lvl + 1
  Prof.save(prof)
  sfx("buy")
end

function TR.move(dx, dy)
  local cur = Tree.byId[UI.treeSel]
  local best, bestScore = nil, 1e9
  for _, n in ipairs(Tree.NODES) do
    if n ~= cur then
      local ox, oy = n.x - cur.x, n.y - cur.y
      local along = ox * dx + oy * dy
      if along > 0 then
        local perp = abs(ox * dy) + abs(oy * dx)
        local score = along + perp * 2.5
        if score < bestScore then best, bestScore = n, score end
      end
    end
  end
  if best then UI.treeSel = best.id end
end

function TR.prestige()
  if not Tree.allMaxed(prof.tree) then say("Max every node to prestige", 40, S.R); return end
  if prof.prestige >= Tree.MAX_PRESTIGE then say("Max prestige reached!", 40, S.Y); return end
  if UI.prestigeArm <= 0 then
    UI.prestigeArm = 60
    say("Press X again to PRESTIGE", 60, S.Y)
    return
  end
  prof.prestige = prof.prestige + 1
  prof.tree = {}
  UI.prestigeArm = 0
  UI.treeSel = "root"
  Prof.save(prof)
  say("PRESTIGE " .. prof.prestige .. "!", 80, S.Y)
  sfx("login")
end

---------------------------------------------------------------------- render helpers
local camX, camY = 0, 0
local drawList, nDraw = {}, 0

local function addDraw(s_, x, y, flip, tint, z)
  nDraw = nDraw + 1
  local e = drawList[nDraw]
  if not e then e = {}; drawList[nDraw] = e end
  e[1], e[2], e[3], e[4], e[5], e[6] = s_, x, y, flip, tint, z
end

local function zsort(a, b) return a[6] < b[6] end

local function line(x1, y1, x2, y2, col)
  local dx, dy = x2 - x1, y2 - y1
  local n = max(1, floor(max(abs(dx), abs(dy))))
  for i = 0, n do scr.pixel(x1 + dx * i / n - camX, y1 + dy * i / n - camY, col) end
end

local function circle(x, y, rad, col, step)
  local n = max(8, floor(rad * 2 / (step or 1)))
  for i = 1, n do
    local a = i / n * 2 * pi
    scr.pixel(x + cos(a) * rad - camX, y + sin(a) * rad - camY, type(col) == "table" and col[random(#col)] or col)
  end
end

local function fmtTime(s)
  s = floor(s)
  return ("%02d:%02d"):format(floor(s / 60), s % 60)
end

local function T(x, y, s, fg, bg) scr.text(x, y, s, fg, bg or S.K) end
local function center(y, s, fg, bg) T(floor((CW - #s) / 2) + 1, y, s, fg, bg) end
local function box(x, y, w, h, bg)
  local blank = (" "):rep(w)
  for yy = y, y + h - 1 do scr.text(x, yy, blank, S.W, bg) end
end
local function frameBox(x, y, w, h, border)
  box(x - 1, y - 1, w + 2, h + 2, border)
  box(x, y, w, h, S.K)
end

local function stars(n)
  return n > 0 and ("*"):rep(n) or ""
end

---------------------------------------------------------------------- render: world
local function renderWorld()
  local sh = UI.shake
  local sx = sh > 0 and random(-sh, sh) or 0
  local sy = sh > 0 and random(-sh, sh) or 0
  camX = floor(p.x + 0.5) - floor(PW / 2) + sx
  camY = floor(p.y - 7 + 0.5) - floor(PH / 2) + sy

  world.drawGround(scr, camX, camY)
  world.drawLakeDecor(scr, camX, camY, frame)

  -- burning ground
  for _, f in ipairs(fires) do
    for _ = 1, floor(f.r * 0.8) do
      local a, d = random() * 2 * pi, sqrt(random()) * f.r
      scr.pixel(f.x + cos(a) * d - camX, f.y + sin(a) * d - camY, (random() < 0.5) and S.O or S.R)
    end
  end

  for _, g in ipairs(gems) do
    scr.sprite(g.v >= 4 and spr.xp_big or spr.xp_orb, g.x - 2 - camX, g.y - 2 - camY)
  end
  for _, it in ipairs(pickups) do
    if it.ttl > 5 * TPS or frame % 6 < 3 then
      local sp = spr[it.kind]
      scr.sprite(sp, it.x - sp.w / 2 - camX, it.y - sp.h - camY + ((frame % 20 < 10) and 0 or -1))
    end
  end

  -- strike target markers
  for _, s in ipairs(strikes) do
    if s.kind ~= "chain" and frame % 4 < 3 then
      local r = (s.kind == "meteor") and 7 or 4
      circle(s.x, s.y, r, S.R, 2)
    end
  end

  if stats.aura >= 1 and p.auraFlash > 0 then
    circle(p.x, p.y - 6, (20 + stats.aura * 8) * stats.area, S.g, 1)
  end
  if stats.firering >= 1 then
    -- flickering flames: jittered ring of fire colours
    local rad = C.fireRingRadius()
    local n = floor(rad * 3)
    local fc = { S.O, S.R, S.Y, S.O, S.R }
    for i = 1, n do
      local a = i / n * 2 * pi + frame * 0.05
      local rr = rad + random(-2, 1)
      scr.pixel(p.x + cos(a) * rr - camX, p.y - 6 + sin(a) * rr - camY, fc[random(5)])
    end
  end

  -- depth-sorted sprites
  nDraw = 0
  world.propsInView(camX, camY, PW, PH, addDraw)
  if R.activeOutposts then
    for _, o in ipairs(R.activeOutposts) do
      if o.state == "alive" then
        addDraw(spr.tent, o.x - 9, o.y - 10, false, nil, o.y)
        addDraw(spr.flag, o.x + 10, o.y - 18, false, nil, o.y - 7)
        addDraw(spr.crate, o.x + 14, o.y - 8, false, nil, o.y - 1)
        addDraw(spr.sandbags, o.x - 34, o.y + 6, false, nil, o.y + 11)
        addDraw(spr.sandbags, o.x - 12, o.y + 18, false, nil, o.y + 23)
        if o.hp > o.maxHp * 0.3 then addDraw(spr.mg_nest, o.x + 22, o.y - 8, o.flip[3], nil, o.y + 4) end
        for k, sp in ipairs(SOLDIER_POS) do
          if o.hp > o.maxHp * (k - 1) / 2.5 then
            addDraw(spr.soldier, o.x + sp[1] - 6, o.y + sp[2] - 13, o.flip[k], nil, o.y + sp[2])
          end
        end
      else
        addDraw(spr.ruined_tent, o.x - 9, o.y - 9, false, nil, o.y - 1)
      end
    end
    for _, f in ipairs(R.followers) do
      local bob = (f.moving and frame % 8 < 4) and -1 or 0
      addDraw(spr.follower, f.x - 6, f.y - 13 + bob, f.flip, (f.hurtCd > 14) and S.R or nil, f.y)
    end
    if R.survivor then
      addDraw(spr.survivor, R.survivor.x - 6, R.survivor.y - 13, false, (R.survivor.hurtCd > 14) and S.R or nil, R.survivor.y)
    end
  end
  for _, m in ipairs(mobs) do
    local sp = spr[m.def.spr]
    local x, y = m.x - sp.w / 2, m.y - sp.h + 1
    if x + sp.w > camX and x < camX + PW and y + sp.h > camY and y < camY + PH then
      local bob = (m.moving and (frame + m.phase) % 12 < 6) and -1 or 0
      local tint = nil
      if (m.frozenT or 0) > 0 then tint = S.C
      elseif (m.shockT or 0) > 0 and frame % 4 < 2 then tint = S.Y end
      if m.flash > 0 then tint = S.W end
      if m.fuse and m.fuse % 4 < 2 then tint = S.W end
      if m.def.ranged and m.cd < 10 and frame % 4 < 2 then tint = S.Y end
      if m.elite and not tint and (frame + m.phase) % 10 < 3 then tint = S.O end
      addDraw(sp, x, y + bob, m.flip, tint, m.y)
    end
  end
  local psp = playerSpr[min(10, prof.prestige)] or spr.player
  local pbob = (p.moving and frame % 8 < 4) and -1 or 0
  local ptint = nil
  if p.iframes > 0 and frame % 4 < 2 then ptint = S.R end
  if p.retalT > 0 and frame % 6 < 2 then ptint = S.O end
  addDraw(psp, floor(p.x + 0.5) - 6, floor(p.y + 0.5) - psp.h + 1 + pbob, p.flip, ptint, p.y)
  for i = nDraw + 1, #drawList do drawList[i] = nil end
  table.sort(drawList, zsort)
  for i = 1, nDraw do
    local e = drawList[i]
    scr.sprite(e[1], e[2] - camX, e[3] - camY, e[4], e[5])
  end

  -- outpost HP bars
  for _, o in ipairs(R.activeOutposts or {}) do
    if o.state == "alive" and o.hp < o.maxHp then
      local bx, by = o.x - 12 - camX, o.y - 26 - camY
      local fill = floor(max(0, o.hp) / o.maxHp * 24)
      scr.rect(bx, by, 24, 2, S.D)
      if fill > 0 then scr.rect(bx, by, fill, 2, S.g) end
    end
  end
  -- off-screen outposts nearby: flag marker on the screen edge
  if frame % 20 < 14 and secs() >= OUTPOST_TIME then
    local n = world.outpostsNear(p.x, p.y, 460, OUT_TMP)
    for i = 1, n do
      local site = OUT_TMP[i]
      local o = R.outposts[site.key]
      if not o or o.state == "alive" then
        local fx, fy = site.x - camX, site.y - 10 - camY
        if fx < 0 or fx > PW or fy < 0 or fy > PH then
          scr.sprite(spr.flag, max(3, min(PW - 9, fx)), max(10, min(PH - 16, fy)))
        end
      end
    end
  end
  -- survivor "!" (pinned to the screen edge when off-screen)
  if R.survivor and frame % 10 < 7 then
    local hx, hy = R.survivor.x - 1 - camX, R.survivor.y - 24 - camY
    hx = max(3, min(PW - 6, hx))
    hy = max(10, min(PH - 12, hy))
    scr.sprite(spr.help, hx, hy)
  end

  -- energy shield bubble
  if stats.shield >= 1 and p.shieldT >= C.shieldCd() then
    circle(p.x, p.y - 7, 11, S.C, 3)
  end

  for _, b in ipairs(bullets) do
    local bx, by = b.x - camX, b.y - camY
    scr.pixel(bx, by, b.col)
    if b.aoe then scr.pixel(bx - b.vx * 0.5, by - b.vy * 0.5, S.O)
    elseif not b.frag then scr.pixel(bx - b.vx * 0.3, by - b.vy * 0.3, b.col) end
  end
  for _, e in ipairs(eshots) do
    local l = sqrt(e.vx * e.vx + e.vy * e.vy)
    local ux, uy = e.vx / l, e.vy / l
    scr.pixel(e.x - camX, e.y - camY, S.A)
    scr.pixel(e.x - ux - camX, e.y - uy - camY, S.B)
    scr.pixel(e.x - ux * 2 - camX, e.y - uy * 2 - camY, S.B)
    scr.pixel(e.x - ux * 3 - camX, e.y - uy * 3 - camY, S.W)
  end
  for _, o in ipairs(orbs) do
    local ox, oy = o.x - camX, o.y - camY
    scr.pixel(ox, oy, S.W); scr.pixel(ox + 1, oy, S.C); scr.pixel(ox, oy + 1, S.C); scr.pixel(ox + 1, oy + 1, S.C)
  end

  -- falling meteors / mortar shells
  for _, s in ipairs(strikes) do
    if s.kind == "meteor" then
      local hx, hy = s.x + s.t * 3, s.y - s.t * 6
      scr.sprite(spr.meteor, hx - 2 - camX, hy - 2 - camY)
      for k = 1, 3 do scr.pixel(hx + k * 3 - camX, hy - k * 6 - camY, (k == 1) and S.Y or S.O) end
    elseif s.kind == "mortar" then
      local hy = s.y - s.t * 7
      scr.pixel(s.x - camX, hy - camY, S.D); scr.pixel(s.x - camX, hy + 1 - camY, S.K)
    end
  end

  if stats.saws >= 1 then
    local ss = (frame % 4 < 2) and spr.saw1 or spr.saw2
    for _, s in ipairs(C.sawPositions()) do scr.sprite(ss, s[1] - 2 - camX, s[2] - 2 - camY) end
  end

  for _, b in ipairs(beams) do
    if b.bolt then
      -- jagged lightning from the sky
      local x, y = b[1], b[2]
      local steps = 8
      for k = 1, steps do
        local nx = b[1] + (b[3] - b[1]) * k / steps + ((k < steps) and random(-4, 4) or 0)
        local ny = b[2] + (b[4] - b[2]) * k / steps
        line(x, y, nx, ny, (b[5] % 2 == 0) and S.Y or S.W)
        x, y = nx, ny
      end
    else
      line(b[1], b[2], b[3] + random(-1, 1), b[4], (b[5] % 2 == 0) and S.Y or S.W)
    end
  end
  for _, q in ipairs(parts) do scr.pixel(q.x - camX, q.y - camY, q.col) end

  -- HP bars on elites and nests
  for _, m in ipairs(mobs) do
    if (m.elite or m.def.static) and not m.dead and m.hp < m.maxHp then
      local sp = spr[m.def.spr]
      local bx, by = floor(m.x - 6 - camX), floor(m.y - sp.h - 2 - camY)
      if bx > -12 and bx < PW and by > 0 and by < PH then
        scr.rect(bx, by, 12, 1, S.K)
        local fill = floor(max(0, m.hp) / m.maxHp * 12)
        if fill > 0 then scr.rect(bx, by, fill, 1, m.def.static and S.Z or S.O) end
      end
    end
  end

  -- floating damage numbers
  if UI.showNums then
    for _, n in ipairs(R.nums) do
      local txt = fmtNum(n.v)
      local x = floor(n.x - #txt * 2 - camX)
      local y = floor(n.y - camY)
      local col = n.crit and S.Y or S.W
      for i = 1, #txt do
        local g = DIGITS[txt:sub(i, i)]
        if g then scr.sprite(g, x, y, false, col) end
        x = x + ((txt:sub(i, i) == ".") and 2 or 4)
      end
    end
  end
end

---------------------------------------------------------------------- render: HUD
local function renderHUD()
  box(1, 1, CW, 1, S.K)
  local filled = ceil(p.hp / p.maxHp * 20)
  T(2, 1, "HP", S.W)
  local bgs = {}
  for i = 1, 20 do bgs[i] = HEX[i <= filled and S.R or S.D] end
  T(5, 1, (" "):rep(20), ("0"):rep(20), table.concat(bgs))
  local info = ("%d/%d   LV %d   %s   Kills %d   Score %d"):format(ceil(p.hp * 10 - 0.01), floor(p.maxHp * 10 + 0.5), p.level, fmtTime(secs()), R.kills, R.score)
  T(27, 1, info, S.W)
  T(82, 1, "DPS " .. fmtNum(R.dps), S.Y)
  local threat = ("Zombie HP %s (x%.1f)  res %d%%"):format(fmtNum(MOBS.zombie.hp * hpMul(secs())), hpMul(secs()), floor(R.res * 100 + 0.5))
  T(CW - 18 - #threat, 1, threat, S.O)
  local who = prof.name .. (prof.prestige > 0 and (" P" .. prof.prestige) or "")
  T(CW - #who, 1, who, S.Y)

  local frac = min(1, p.xp / p.xpNext)
  local fillW = floor(frac * CW)
  local label = ("LEVEL %d   %d / %d XP"):format(p.level, floor(p.xp), p.xpNext)
  local lx = floor((CW - #label) / 2) + 1
  local chars, fg2, bg2 = {}, {}, {}
  for x = 1, CW do
    local on = x <= fillW
    local ch = " "
    if x >= lx and x < lx + #label then ch = label:sub(x - lx + 1, x - lx + 1) end
    chars[x], fg2[x], bg2[x] = ch, on and "f" or "8", HEX[on and S.C or S.D]
  end
  T(1, 2, table.concat(chars), table.concat(fg2), table.concat(bg2))

  local row = 4
  if R.boss and not R.boss.dead then
    local bw = min(CW - 30, 100)
    local bx = floor((CW - bw) / 2) + 1
    T(bx - 13, 3, " GRAVE KING ", S.W, S.R)
    local bf = floor(max(0, R.boss.hp) / R.boss.maxHp * bw)
    T(bx, 3, (" "):rep(bw), S.W, S.D)
    if bf > 0 then T(bx, 3, (" "):rep(bf), S.W, S.R) end
    row = 5
  end
  if UI.msgTimer > 0 and UI.msg ~= "" then center(row, " " .. UI.msg .. " ", UI.msgCol, S.K) end

  box(1, CH, CW, 1, S.K)
  local x = 2
  for i = 1, 4 do
    local lbl = " " .. i .. " " .. (p.unlocked[i] and WEAPONS[i].name or "-----") .. " "
    if i == p.weapon then T(x, CH, lbl, S.K, S.Y)
    else T(x, CH, lbl, p.unlocked[i] and S.W or S.D, S.K) end
    x = x + #lbl + 1
  end
  local extra = ""
  if stats.shield >= 1 then extra = extra .. ((p.shieldT >= C.shieldCd()) and "SHIELD UP   " or "shield ...   ") end
  if stats.revive >= 1 then extra = extra .. ("Revives %d   "):format(floor(stats.revive + 0.5) - p.revUsed) end
  if #R.followers > 0 then extra = extra .. ("Followers %d/2   "):format(#R.followers) end
  T(x + 2, CH, extra, S.C)
  T(CW - 30, CH, "H numbers   P pause / build", S.A)
end

---------------------------------------------------------------------- render: overlays
local function statLines()
  local st = stats
  return {
    ("All damage   x%.2f"):format(st.dmg),
    ("Gun damage   x%.2f"):format(st.gundmg),
    ("Area damage  x%.2f"):format(st.aoedmg),
    ("Fire rate    x%.2f"):format(st.rate),
    ("Projectiles  +%d   Pierce %d"):format(floor(st.proj + 0.5), floor(st.pierce + 0.5)),
    ("Crit         %d%%  x%.2f"):format(floor(st.crit * 100 + 0.5), st.critdmg),
    ("Area size    x%.2f"):format(st.area),
    ("Max HP       %d"):format(floor(p.maxHp * 10 + 0.5)),
    ("Armor        %.1f  (-%d%% dmg)"):format(st.armor, floor(I.armorReduction(st.armor) * 100 + 0.5)),
    ("Dodge        %d%%"):format(floor(st.dodge * 100 + 0.5)),
    ("Lifesteal    %.1f%%"):format(st.lifesteal * 100),
    ("Move speed   x%.2f"):format(st.speed),
    ("XP gain      x%.2f"):format(st.xp),
    ("Luck         %.1f"):format(st.luck),
    ("Mob spawns   x%.2f"):format(st.spawn),
  }
end

local function sourceLines(n)
  local list, total = {}, 0
  for src, v in pairs(R.dmgSrc) do list[#list + 1] = { src, v }; total = total + v end
  table.sort(list, function(a, b) return a[2] > b[2] end)
  local L = {}
  local t = max(1, secs())
  for i = 1, min(n, #list) do
    local e = list[i]
    L[i] = ("%-15s %7s %4d%% %7s/s"):format(e[1], fmtNum(e[2]), floor(e[2] / max(1, total) * 100 + 0.5), fmtNum(e[2] / t))
  end
  return L, total
end

local function ownedList()
  local L = {}
  for _, rk in ipairs({ "legendary", "epic", "rare", "common" }) do
    for _, it in ipairs(I.LIST) do
      if it.rarity == rk and (owned[it.id] or 0) > 0 then
        L[#L + 1] = { it.name .. (owned[it.id] > 1 and (" x" .. owned[it.id]) or ""), P.slot[I.RARITY[rk].col] }
      end
    end
  end
  return L
end

local function renderPick()
  local n = #R.offers
  local cardW = min(44, floor((CW - 8 - (n - 1) * 2) / n))
  local w = cardW * n + (n - 1) * 2 + 4
  local h = 24
  local x0, y0 = floor((CW - w) / 2) + 1, floor((CH - h) / 2) + 1
  frameBox(x0, y0, w, h, R.banishMode and S.R or S.Y)
  center(y0 + 1, R.banishMode and "BANISH which item? (gone for this run)" or C.pickTitle(), R.banishMode and S.R or S.Y)
  for i, it in ipairs(R.offers) do
    local cx = x0 + 2 + (i - 1) * (cardW + 2)
    local rar = I.RARITY[it.rarity]
    local rc = P.slot[rar.col]
    box(cx, y0 + 3, cardW, 17, S.D)
    T(cx, y0 + 3, (" "):rep(cardW), S.K, rc)
    T(cx + 1, y0 + 3, "[" .. i .. "]  " .. rar.name, S.K, rc)
    T(cx + 2, y0 + 5, it.name, S.W, S.D)
    if it.max > 1 and it.max < 999 then
      T(cx + 2, y0 + 6, ("owned %d / %d"):format(owned[it.id] or 0, it.max), S.A, S.D)
    end
    for j, ln in ipairs(it.lines) do
      local bad = ln:sub(1, 1) == "!"
      local text = bad and ln:sub(2) or ln
      local col = bad and S.R or S.g
      if text == "EVOLUTION" then col = S.Y end
      T(cx + 2, y0 + 7 + j, text:sub(1, cardW - 3), col, S.D)
    end
    local need = I.needsText(it)
    if need then
      -- wrap onto two lines if the card is narrow
      local w = cardW - 4
      T(cx + 2, y0 + 16, need:sub(1, w), S.A, S.D)
      if #need > w then T(cx + 2, y0 + 17, need:sub(w + 1, 2 * w), S.A, S.D) end
    end
  end
  local keysTxt = (n == 4) and "1 2 3 4  pick" or "1 2 3  pick"
  if R.rerolls > 0 then keysTxt = keysTxt .. "      R reroll (" .. R.rerolls .. ")" end
  if R.banishes > 0 then keysTxt = keysTxt .. "      B banish (" .. R.banishes .. ")" end
  center(y0 + 22, keysTxt, S.W)
end

local function renderPause()
  local w, h = min(CW - 4, 130), 28
  local x0, y0 = floor((CW - w) / 2) + 1, floor((CH - h) / 2) + 1
  frameBox(x0, y0, w, h, S.D)
  center(y0 + 1, "PAUSED", S.Y)
  T(x0 + 3, y0 + 3, "YOUR STATS", S.A)
  for i, l in ipairs(statLines()) do T(x0 + 3, y0 + 4 + i, l, S.W) end
  T(x0 + 46, y0 + 3, "YOUR ITEMS", S.A)
  local items = ownedList()
  if #items == 0 then T(x0 + 46, y0 + 5, "nothing yet", S.D) end
  for i, e in ipairs(items) do
    if i <= 20 then T(x0 + 46, y0 + 4 + i, e[1], e[2]) end
  end
  if w >= 120 then
    local lines, total = sourceLines(18)
    T(x0 + 78, y0 + 3, "DAMAGE BY SOURCE", S.A)
    T(x0 + 78, y0 + 4, ("total %s   now %s/s"):format(fmtNum(total), fmtNum(R.dps)), S.Y)
    for i, l in ipairs(lines) do T(x0 + 78, y0 + 5 + i, l, S.W) end
  end
  center(y0 + 26, "P / SPACE resume      Q end run", S.W)
end

local function renderDead()
  local w, h = 72, 30
  local x0, y0 = floor((CW - w) / 2) + 1, floor((CH - h) / 2) + 1
  frameBox(x0, y0, w, h, S.R)
  center(y0 + 2, "Y O U   D I E D", S.R)
  center(y0 + 5, "Survived " .. fmtTime(secs()), S.W)
  center(y0 + 6, ("Level %d    Kills %d    Bosses %d"):format(p.level, R.kills, R.bossKills), S.W)
  center(y0 + 8, "Score " .. R.score, S.Y)
  if R.newBest then
    if frame % 10 < 6 then center(y0 + 9, "NEW BEST!", S.g) end
  else
    center(y0 + 9, "Best " .. prof.best, S.A)
  end
  center(y0 + 11, ("+%d souls   (total %d)"):format(R.soulsEarned, prof.souls), S.C)
  center(y0 + 12, ("Survivors rescued %d    Nests destroyed %d"):format(R.rescued, R.nestsCleared), S.A)
  local items = ownedList()
  local names = {}
  for i, e in ipairs(items) do if i <= 6 then names[#names + 1] = e[1] end end
  if #names > 0 then center(y0 + 14, table.concat(names, ", "):sub(1, w - 4), S.A) end
  local lines, total = sourceLines(7)
  center(y0 + 16, "DAMAGE BY SOURCE   (total " .. fmtNum(total) .. ")", S.A)
  for i, l in ipairs(lines) do center(y0 + 17 + i, l, S.W) end
  if R.deadTimer > 30 then center(y0 + 27, "SPACE new run     T skill tree     Q title", S.g) end
end

local function renderTitle()
  -- centre: logo + controls
  local w, h = 62, 30
  local x0, y0 = floor((CW - w) / 2) + 1, floor((CH - h) / 2) + 1
  frameBox(x0, y0, w, h, S.D)
  center(y0 + 2, "D  E  A  D     Z  O  N  E", S.R)
  center(y0 + 3, "survive the endless undead", S.A)
  local lines = {
    "WASD        move",
    "SPACE       shoot (hold)",
    "ARROWS      aim + shoot",
    "1 2 3 4     switch weapon",
    "1 2 3       pick item on level up",
    "R / B       reroll / banish items",
    "P           pause / see your build",
  }
  for i, l in ipairs(lines) do T(x0 + 13, y0 + 5 + i, l, S.W) end
  if frame % 20 < 14 then center(y0 + 17, "SPACE  start run", S.g) end
  center(y0 + 19, "T  skill tree", S.C)
  center(y0 + 20, "N  type a name to log in", S.A)
  center(y0 + 21, "Q  quit", S.A)
  if detector then
    center(y0 + 24, "Player Detector: connected", S.g)
    center(y0 + 25, "Stand next to it (or right-click it) to log in", S.Y)
  else
    center(y0 + 24, "Player Detector: not found", S.R)
    center(y0 + 25, "It must touch the computer (or use a wired modem)", S.A)
  end

  -- left: profile
  local lw = 34
  local lx = x0 - lw - 4
  if lx >= 2 then
    frameBox(lx, y0, lw, 16, S.D)
    T(lx + 2, y0 + 1, "PLAYER", S.A)
    T(lx + 2, y0 + 3, prof.name, S.Y)
    if prof.prestige > 0 then T(lx + 2, y0 + 4, "Prestige " .. prof.prestige .. " " .. stars(prof.prestige), S.O) end
    T(lx + 2, y0 + 6, "Souls        " .. prof.souls, S.C)
    T(lx + 2, y0 + 7, "Best score   " .. prof.best, S.W)
    T(lx + 2, y0 + 8, "Longest run  " .. fmtTime(prof.bestTime), S.W)
    T(lx + 2, y0 + 9, "Runs         " .. prof.runs, S.W)
    T(lx + 2, y0 + 10, "Kills        " .. (prof.kills or 0), S.W)
    local lv, mx = 0, Tree.totalLevels()
    for _, n in ipairs(Tree.NODES) do lv = lv + (prof.tree[n.id] or 0) end
    T(lx + 2, y0 + 12, ("Tree %d / %d"):format(lv, mx), S.g)
  end

  -- right: leaderboard
  local rx = x0 + w + 4
  if rx + 36 <= CW then
    frameBox(rx, y0, 36, 16, S.D)
    T(rx + 2, y0 + 1, "LEADERBOARD", S.Y)
    if #UI.board == 0 then T(rx + 2, y0 + 3, "no runs yet", S.D) end
    for i, e in ipairs(UI.board) do
      local name = e.name:sub(1, 12)
      local ps = (e.prestige or 0) > 0 and ("P" .. e.prestige) or "  "
      T(rx + 2, y0 + 2 + i, ("%2d. %-12s %3s %7d"):format(i, name, ps, e.best or 0), (e.name == prof.name) and S.Y or S.W)
    end
  end

  if UI.msgTimer > 0 then center(y0 + h + 2, " " .. UI.msg .. " ", UI.msgCol, S.K) end
end

local function renderNaming()
  local w, h = 50, 9
  local x0, y0 = floor((CW - w) / 2) + 1, floor((CH - h) / 2) + 1
  frameBox(x0, y0, w, h, S.Y)
  center(y0 + 1, "TYPE YOUR NAME", S.Y)
  local shown = UI.nameBuf .. ((frame % 10 < 5) and "_" or " ")
  center(y0 + 4, shown, S.W)
  center(y0 + 7, "ENTER confirm     TAB cancel", S.A)
end

---------------------------------------------------------------------- render: skill tree
local TREE_SX, TREE_SY, BOX_W = 22, 6, 18

local function renderTree()
  scr.fillBase(function() return BLACK end)
  local sel = Tree.byId[UI.treeSel]
  local topRow, bottomRow = 3, CH - 11
  local midX = floor(CW / 2)
  local midY = floor((topRow + bottomRow) / 2)
  local function cellOf(n)
    return midX + (n.x - sel.x) * TREE_SX, midY + (n.y - sel.y) * TREE_SY
  end
  local lv = prof.tree

  -- connections (pixel layer)
  for _, n in ipairs(Tree.NODES) do
    if n.parent then
      local par = Tree.byId[n.parent]
      local ax, ay = cellOf(par)
      local bx, by = cellOf(n)
      local col = ((lv[n.id] or 0) > 0) and P.slot[Tree.BRANCH_COL[n.branch]] or S.D
      local px1, py1, px2, py2 = ax * 2 - 1, ay * 3 - 2, bx * 2 - 1, by * 3 - 2
      local steps = max(abs(px2 - px1), abs(py2 - py1))
      for i = 0, steps do
        local x = px1 + (px2 - px1) * i / steps
        local y = py1 + (py2 - py1) * i / steps
        if y >= (topRow - 1) * 3 and y < bottomRow * 3 then scr.pixel(x, y, col) end
      end
    end
  end

  -- nodes (text layer)
  for _, n in ipairs(Tree.NODES) do
    local cx, cy = cellOf(n)
    local x = cx - floor(BOX_W / 2)
    if cy - 1 >= topRow and cy + 1 <= bottomRow and x + BOX_W >= 1 and x <= CW then
      local l = lv[n.id] or 0
      local bcol = P.slot[Tree.BRANCH_COL[n.branch]]
      local unlocked = Tree.unlocked(n, lv)
      local bg, fg, sub
      if n.id == UI.treeSel then bg, fg = S.W, S.K
      elseif l >= n.max then bg, fg = bcol, S.K
      elseif l > 0 then bg, fg = S.D, bcol
      elseif unlocked then bg, fg = S.D, S.W
      else bg, fg = S.K, S.A end
      local name = n.name:sub(1, BOX_W - 2)
      local lvTxt = ("%d/%d"):format(l, n.max)
      if n.key then lvTxt = l > 0 and "KEYSTONE" or "keystone" end
      if l >= n.max then sub = "MAX"
      elseif not unlocked then sub = "locked"
      else sub = Tree.cost(n, l + 1) .. " souls" end
      local pad = function(s) s = s:sub(1, BOX_W - 2); return " " .. s .. (" "):rep(BOX_W - 1 - #s) end
      T(x, cy - 1, pad(name), fg, bg)
      T(x, cy, pad(lvTxt), fg, bg)
      local subCol = fg
      if l < n.max and unlocked and n.id ~= UI.treeSel then subCol = (prof.souls >= Tree.cost(n, l + 1)) and S.g or S.R end
      T(x, cy + 1, pad(sub), subCol, bg)
    end
  end

  -- header
  box(1, 1, CW, 1, S.K)
  T(2, 1, "SKILL TREE", S.Y)
  T(16, 1, prof.name .. (prof.prestige > 0 and ("  Prestige " .. prof.prestige .. " " .. stars(prof.prestige)) or ""), S.W)
  local soulsTxt = "Souls " .. prof.souls
  T(CW - #soulsTxt - 1, 1, soulsTxt, S.C)

  -- info panel
  local py = CH - 9
  box(1, py - 1, CW, 11, S.D)
  box(2, py, CW - 2, 9, S.K)
  local l = lv[sel.id] or 0
  local bcol = P.slot[Tree.BRANCH_COL[sel.branch]]
  T(4, py + 1, sel.name, bcol)
  T(4 + #sel.name + 3, py + 1, ("level %d / %d"):format(l, sel.max), S.W)
  T(4, py + 2, sel.desc .. ((sel.max > 1 and not sel.key) and "  (per level)" or ""), S.W)
  if l >= sel.max then
    T(4, py + 4, "MAXED", S.g)
  elseif not Tree.unlocked(sel, lv) then
    T(4, py + 4, "Locked - buy " .. Tree.byId[sel.parent].name .. " first", S.R)
  else
    local cost = Tree.cost(sel, l + 1)
    T(4, py + 4, ("Next level: %d souls"):format(cost), (prof.souls >= cost) and S.g or S.R)
  end
  local pr = prof.prestige
  local prTxt = ("Prestige %d/%d   base stats +%d%% of a full tree   mobs +%d%% HP   souls +%d%%"):format(
    pr, Tree.MAX_PRESTIGE, pr * 10, floor((Tree.prestigeMobHp(pr) - 1) * 100 + 0.5), floor((Tree.prestigeSouls(pr) - 1) * 100 + 0.5))
  T(4, py + 6, prTxt, S.O)
  if Tree.allMaxed(lv) and pr < Tree.MAX_PRESTIGE then
    T(4, py + 7, "EVERYTHING MAXED  -  press X to PRESTIGE", (frame % 10 < 6) and S.Y or S.O)
  end
  local keysTxt = "WASD move    SPACE buy    X prestige    Q back"
  T(CW - #keysTxt - 3, py + 8, keysTxt, S.A)
  if UI.msgTimer > 0 then center(py - 2, " " .. UI.msg .. " ", UI.msgCol, S.K) end
end

local function render()
  if state == "tree" then
    renderTree()
  else
    if state == "title" or state == "naming" then p.x = p.x + 0.6 end
    renderWorld()
    if state ~= "title" and state ~= "naming" then renderHUD() end
    if state == "title" then renderTitle()
    elseif state == "naming" then renderTitle(); renderNaming()
    elseif state == "pick" then renderPick()
    elseif state == "paused" then renderPause()
    elseif state == "dead" then renderDead() end
  end
  scr.present()
end

---------------------------------------------------------------------- input
local NUM = { [keys.one] = 1, [keys.two] = 2, [keys.three] = 3, [keys.four] = 4 }

local function startRun()
  newRun()
  state = "play"
end

local function toTitle()
  newRun()
  state = "title"
  UI.board = Prof.leaderboard(10)
end

local function onKey(k)
  if state == "title" then
    if k == keys.space or k == keys.enter then startRun()
    elseif k == keys.t then state = "tree"
    elseif k == keys.n then state = "naming"; UI.nameBuf = ""
    elseif k == keys.q then running = false end
  elseif state == "naming" then
    if k == keys.enter then
      if #UI.nameBuf > 0 then login(UI.nameBuf) end
      state = "title"
    elseif k == keys.backspace then UI.nameBuf = UI.nameBuf:sub(1, -2)
    elseif k == keys.tab then state = "title" end
  elseif state == "play" then
    if k == keys.h then
      UI.showNums = not UI.showNums
      say(UI.showNums and "Damage numbers ON" or "Damage numbers OFF", 25, S.W)
    elseif k == keys.p then state = "paused"
    elseif NUM[k] then
      local n = NUM[k]
      if p.unlocked[n] then p.weapon = n; say(WEAPONS[n].name, 25, S.W)
      else say("Weapon " .. n .. " is locked - find it in level-up items", 40, S.A) end
    end
  elseif state == "pick" then
    local n = NUM[k]
    if n and n <= #R.offers then C.choose(n)
    elseif k == keys.r and R.rerolls > 0 and not R.banishMode then
      R.rerolls = R.rerolls - 1
      R.offers = I.roll(owned, stats.luck, C.offerCount(), R.offerKind == "chest" and "epic" or nil, R.banned)
    elseif k == keys.b and R.banishes > 0 then
      R.banishMode = not R.banishMode
    end
  elseif state == "paused" then
    if k == keys.p or k == keys.space then state = "play"
    elseif k == keys.q then C.gameOver() end
  elseif state == "dead" then
    if R.deadTimer > 30 then
      if k == keys.space or k == keys.enter then startRun()
      elseif k == keys.t then state = "tree"
      elseif k == keys.q then toTitle() end
    end
  elseif state == "tree" then
    if k == keys.w then TR.move(0, -1)
    elseif k == keys.s then TR.move(0, 1)
    elseif k == keys.a then TR.move(-1, 0)
    elseif k == keys.d then TR.move(1, 0)
    elseif k == keys.space or k == keys.enter then TR.buy()
    elseif k == keys.x then TR.prestige()
    elseif k == keys.q or k == keys.t then toTitle() end
  end
end

---------------------------------------------------------------------- controller screen (computer)
local function drawController()
  if out == native then return end
  native.setBackgroundColour(colours.black)
  native.clear()
  local lines = {
    { "DEAD ZONE", colours.red },
    { "Game is on the monitor wall.", colours.lightGrey },
    { "Keep this screen open - it's your controller.", colours.lightGrey },
    { "", colours.white },
    { "WASD     move", colours.white },
    { "SPACE    shoot", colours.white },
    { "ARROWS   aim + shoot", colours.white },
    { "1-4      weapons / pick items", colours.white },
    { "R / B    reroll / banish", colours.white },
    { "P        pause / build", colours.white },
    { "T        skill tree (title screen)", colours.white },
  }
  for i, l in ipairs(lines) do
    native.setCursorPos(2, i + 1)
    native.setTextColour(l[2])
    native.write(l[1])
  end
  -- what is attached (helps when the Player Detector isn't found)
  local y = #lines + 3
  native.setCursorPos(2, y)
  native.setTextColour(colours.yellow)
  native.write("Attached peripherals:")
  for _, name in ipairs(peripheral.getNames()) do
    y = y + 1
    native.setCursorPos(3, y)
    native.setTextColour((name == detectorName) and colours.lime or colours.lightGrey)
    native.write(name .. " = " .. table.concat({ peripheral.getType(name) }, ", "))
  end
end

---------------------------------------------------------------------- main loop
local function main()
  UI.board = Prof.leaderboard(10)
  newRun()
  state = "title"
  drawController()
  local timer = os.startTimer(0.05)
  while running do
    local ev = { os.pullEventRaw() }
    local e = ev[1]
    if e == "timer" and ev[2] == timer then
      timer = os.startTimer(0.05)
      frame = frame + 1
      if state == "play" then update() end
      if state == "dead" then R.deadTimer = R.deadTimer + 1 end
      if state ~= "play" and UI.msgTimer > 0 then UI.msgTimer = UI.msgTimer - 1 end
      if UI.prestigeArm > 0 then UI.prestigeArm = UI.prestigeArm - 1 end
      render()
    elseif e == "key" then
      held[ev[2]] = true
      if not ev[3] then onKey(ev[2]) end
    elseif e == "key_up" then
      held[ev[2]] = nil
    elseif e == "char" and state == "naming" then
      if #UI.nameBuf < 16 and ev[2]:match("[%w_%-]") then UI.nameBuf = UI.nameBuf .. ev[2] end
    elseif e == "playerClick" then
      -- Advanced Peripherals Player Detector: right-click to log in
      if state == "title" or state == "dead" or state == "tree" or state == "naming" or state == "paused" then
        login(ev[2])
        if state == "naming" then state = "title" end
      end
    elseif e == "dz_login" then
      if state == "title" or state == "dead" or state == "tree" then login(ev[2]) end
    elseif e == "peripheral" or e == "peripheral_detach" then
      findDetector()
      drawController()
    elseif e == "terminate" then
      running = false
    end
  end
end

-- the Player Detector is asked in a separate coroutine: its calls wait on the
-- server and would otherwise swallow the game's timer and key events
local function detectorLoop()
  while running do
    if detector and (state == "title" or state == "dead" or state == "tree") then
      local ok, list = pcall(detector.getPlayersInRange, 5)
      if ok and type(list) == "table" and #list == 1 and type(list[1]) == "string" then
        os.queueEvent("dz_login", list[1])
      end
    end
    sleep(2)
  end
end

local ok, err = xpcall(function() parallel.waitForAny(main, detectorLoop) end, debug and debug.traceback or nil)
if not ok then
  pcall(function()
    local f = fs.open("/" .. dir .. "/crash.log", "w")
    f.write(os.date and (tostring(os.date()) .. "\n") or "")
    f.write(tostring(err))
    f.close()
  end)
end
P.restore(out)
out.setBackgroundColour(colours.black)
out.clear()
if mon then mon.setTextScale(1) end
native.setBackgroundColour(colours.black)
native.setTextColour(colours.white)
native.clear()
native.setCursorPos(1, 1)
if not ok then
  printError(err)
  print("Saved to /" .. dir .. "/crash.log - send it to Claude")
  pcall(function()
    out.setTextColour(colours.red)
    out.setCursorPos(2, 2)
    out.write("DEAD ZONE crashed - details on the computer screen and in crash.log")
  end)
else
  print("Thanks for playing DEAD ZONE!")
end
