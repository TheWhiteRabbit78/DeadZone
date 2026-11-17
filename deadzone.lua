--[[
  DEAD ZONE  v1  -  pixel-art roguelite survivor shooter for CC:Tweaked
  Advanced Computer + Advanced Monitor wall (max size 8x6 recommended)
  Optional: a Speaker next to the computer for sound.

  Keep the computer's screen open while playing - it's your controller.
    WASD        move (8 directions)
    SPACE       shoot where you face (hold for auto-fire)
    ARROWS      aim + shoot in that direction
    1 2 3 4     switch weapon
    1 2 3       pick an item on level up,  R = reroll
    P           pause (shows your build)
]]

local dir = fs.getDir(shell.getRunningProgram())
package.path = "/" .. dir .. "/?.lua;" .. package.path

local P = require("dz.palette")
local G = require("dz.gfx")
local SPR = require("dz.sprites")
local World = require("dz.world")
local I = require("dz.items")

local floor, ceil, sqrt, abs = math.floor, math.ceil, math.sqrt, math.abs
local min, max, random = math.min, math.max, math.random
local sin, cos, pi = math.sin, math.cos, math.pi
local atan2 = math.atan2 or math.atan

local TPS = 20
local MAX_MOBS = 150
local SAVE_FILE = "/" .. dir .. "/save.dat"
local S = P.slot

---------------------------------------------------------------------- display
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

---------------------------------------------------------------------- sprites
local spr = {}
for name, rows in pairs(SPR) do spr[name] = G.compile(rows) end

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
}
local SPAWN_ORDER = { "zombie", "ghoul", "brute", "skeleton", "bomb_imp" }
local DEATH_COL = { zombie = S.Z, ghoul = S.A, brute = S.Z, skeleton = S.W, bomb_imp = S.R, boss = S.W }

---------------------------------------------------------------------- save
local save = { best = 0, bestTime = 0, runs = 0 }
local function loadSave()
  if fs.exists(SAVE_FILE) then
    local f = fs.open(SAVE_FILE, "r")
    local ok, t = pcall(textutils.unserialize, f.readAll())
    f.close()
    if ok and type(t) == "table" then
      for k, v in pairs(t) do save[k] = v end
    end
  end
end
local function writeSave()
  local f = fs.open(SAVE_FILE, "w")
  f.write(textutils.serialize(save))
  f.close()
end

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
}
local function sfx(kind)
  if not speaker then return end
  local d = SOUNDS[kind]
  if (sndCd[kind] or -999) + d[1] > frame then return end
  sndCd[kind] = frame
  pcall(d[2])
end

---------------------------------------------------------------------- run state
local state = "title"
local running = true
local held = {}
local world
local p, mobs, bullets, eshots, gems, pickups, parts, beams
local tick, kills, score
local owned, stats
local spawnTimer, nextHorde, nextBoss, boss, announced
local offers, offerTitle, rerolls
local msg, msgCol, msgTimer = "", S.Y, 0
local shake = 0
local deadTimer, newBest = 0, false
local grid = {}

local function secs() return tick / TPS end
local function hpMul(s) return 1 + 0.25 * (s / 60) ^ 1.4 end
local function speedMul(s) return 1 + min(0.45, s / 800) end
local function dmgAdd(s) return floor(s / 240) end
local function xpFor(l) return floor(5 + l * 4 + l ^ 1.8) end
local function say(t, ticks, col) msg, msgTimer, msgCol = t, ticks or 60, col or S.Y end

local function removeAt(list, i)
  local n = #list
  list[i] = list[n]
  list[n] = nil
end

local function recompute()
  stats = I.compute(owned)
  local newMax = max(1, floor(stats.maxhp + 0.5))
  p.maxHp = newMax
  if p.hp > newMax then p.hp = newMax end
end

local function newRun()
  world = World.new(spr, random(1, 99999))
  p = {
    x = 0, y = 0, vx = 0, vy = 0, fx = 1, fy = 0, flip = false,
    hp = 10, maxHp = 10, cd = 0, iframes = 0,
    xp = 0, level = 1, xpNext = xpFor(1), pending = 0,
    weapon = 1, unlocked = { true, false, false, false },
    regenT = 0, drainT = 0, sawA = 0, auraT = 0, auraFlash = 0, moving = false,
  }
  owned = {}
  recompute()
  p.hp = p.maxHp
  mobs, bullets, eshots, gems, pickups, parts, beams = {}, {}, {}, {}, {}, {}, {}
  tick, kills, score = 0, 0, 0
  spawnTimer, nextHorde, nextBoss, boss = 20, 60 * TPS, 180 * TPS, nil
  announced = { zombie = true }
  rerolls = 3
  shake = 0
  newBest = false
  say("Survive!  WASD move, SPACE shoot", 80, S.W)
end

---------------------------------------------------------------------- particles / fx
local function addPart(x, y, vx, vy, life, col)
  if #parts < 350 then parts[#parts + 1] = { x = x, y = y, vx = vx, vy = vy, life = life, col = col } end
end

local function burst(x, y, n, col, spd)
  for _ = 1, n do
    local a = random() * 2 * pi
    local v = (0.4 + random()) * (spd or 1.5)
    addPart(x, y, cos(a) * v, sin(a) * v, random(5, 12), col)
  end
end

---------------------------------------------------------------------- spatial grid (16 px cells)
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

-- call fn(m) for live mobs whose cell is within `cells` of (x, y)
local function forNear(x, y, cells, fn)
  local gx, gy = floor(x / 16), floor(y / 16)
  for yy = gy - cells, gy + cells do
    for xx = gx - cells, gx + cells do
      local l = grid[gkey(xx, yy)]
      if l then
        for i = 1, #l do
          local m = l[i]
          if not m.dead then
            if fn(m) then return end
          end
        end
      end
    end
  end
end

---------------------------------------------------------------------- combat
local gameOver, killMob, explode

local function hurtPlayer(dmg)
  if p.iframes > 0 or state ~= "play" then return end
  if random() < stats.dodge then
    p.iframes = 8
    addPart(p.x, p.y - 16, 0, -0.5, 10, S.C)
    return
  end
  dmg = dmg * (1 - min(0.6, stats.armor * 0.15))
  p.hp = p.hp - dmg
  p.iframes = 14
  shake = max(shake, 3)
  burst(p.x, p.y - 7, 6, S.R, 1.2)
  sfx("hurt")
  if p.hp <= 0 then
    p.hp = 0
    gameOver()
  end
end

local function damageMob(m, dmg, kx, ky)
  if m.dead then return end
  m.hp = m.hp - dmg
  m.flash = 2
  if stats.lifesteal > 0 then p.hp = min(p.maxHp, p.hp + dmg * stats.lifesteal) end
  if kx and not m.def.heavy then
    local l = sqrt(kx * kx + ky * ky)
    if l > 0 then
      m.x = m.x + kx / l * 2.5
      m.y = m.y + ky / l * 2.5
    end
  end
  if m.hp <= 0 then killMob(m) end
end

explode = function(x, y, rad, dmg, hurtsPlayer, fromPlayer)
  if fromPlayer then
    rad = rad * stats.area
    dmg = dmg * stats.boom
  end
  for _, m in ipairs(mobs) do
    if not m.dead then
      local dx, dy = m.x - x, (m.y - 6) - y
      if dx * dx + dy * dy <= (rad + m.def.r) ^ 2 then damageMob(m, dmg) end
    end
  end
  if hurtsPlayer then
    local dx, dy = p.x - x, (p.y - 6) - y
    if dx * dx + dy * dy <= rad * rad then hurtPlayer(3 + dmgAdd(secs())) end
  end
  local cols = { S.O, S.Y, S.R, S.W }
  for _ = 1, floor(10 + rad) do
    local a = random() * 2 * pi
    local v = rad / 7 * (0.5 + random())
    addPart(x, y, cos(a) * v, sin(a) * v, random(4, 9), cols[random(4)])
  end
  shake = max(shake, 4)
  sfx("boom")
end

local function dropGem(x, y, v)
  if #gems >= 220 then
    local g = gems[random(#gems)]
    g.v = g.v + v
    return
  end
  gems[#gems + 1] = { x = x + random(-2, 2), y = y + random(-2, 2), v = v }
end

killMob = function(m)
  if m.dead then return end
  m.dead = true
  kills = kills + 1
  score = score + m.def.score
  dropGem(m.x, m.y - 4, m.def.xp * (1 + secs() / 240))
  burst(m.x, m.y - 6, 8, DEATH_COL[m.kind] or S.R, 1.4)
  burst(m.x, m.y - 6, 4, S.R, 0.8)
  sfx("kill")
  if m.def.boss then
    pickups[#pickups + 1] = { x = m.x, y = m.y, kind = "chest", ttl = 9999 }
    for _ = 1, 3 do
      pickups[#pickups + 1] = { x = m.x + random(-14, 14), y = m.y + random(-10, 10), kind = "heart", ttl = 60 * TPS }
    end
    say("BOSS DOWN!  Grab the chest", 90, S.Y)
    boss = nil
    explode(m.x, m.y - 10, 30, 0, false, false)
  else
    local r = random()
    if r < 0.025 then
      pickups[#pickups + 1] = { x = m.x, y = m.y, kind = "heart", ttl = 30 * TPS }
    elseif r < 0.032 then
      pickups[#pickups + 1] = { x = m.x, y = m.y, kind = "magnet", ttl = 30 * TPS }
    end
  end
  if m.def.bomb and not m.exploded then
    m.exploded = true
    explode(m.x, m.y - 6, 26, 10 * hpMul(secs()), false, false)
  elseif stats.corpse > 0 and random() < stats.corpse then
    explode(m.x, m.y - 6, 18, m.maxHp * 0.6, false, true)
  end
end

local function spawnMob(kind, x, y)
  local d = MOBS[kind]
  local s = secs()
  local m = {
    kind = kind, def = d, x = x, y = y,
    hp = d.hp * hpMul(s), speed = d.speed * speedMul(s) * (0.9 + random() * 0.2),
    flash = 0, cd = random(30, 70), phase = random(0, 11), fuse = nil, flip = false,
  }
  m.maxHp = m.hp
  mobs[#mobs + 1] = m
  return m
end

local function spawnPos()
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

local function pickType(s)
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
local function fire()
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

  local fan = w.fan * (1 + (proj - w.proj) * 0.2)
  local dmg = w.dmg * stats.dmg
  for i = 1, proj do
    local a = baseA + (random() - 0.5) * w.jitter
    if proj > 1 then a = a - fan / 2 + fan * (i - 1) / (proj - 1) end
    local ca, sa = cos(a), sin(a)
    bullets[#bullets + 1] = {
      x = ox + ca * 6, y = oy + sa * 6, vx = ca * w.speed, vy = sa * w.speed,
      life = floor(range / w.speed), dmg = dmg, pierce = floor(stats.pierce + 0.5),
      ric = floor(stats.ricochet + 0.5), hit = {}, col = w.col, aoe = w.aoe,
    }
  end
  addPart(ox + p.fx * 8, oy + p.fy * 8, 0, 0, 2, S.Y)
  p.cd = max(1, floor(w.cd / stats.rate + 0.5))
  sfx("shoot")
end

local function nearestMob(x, y, maxD, exclude)
  local best, bd = nil, maxD * maxD
  for _, m in ipairs(mobs) do
    if not m.dead and not exclude[m] then
      local dx, dy = m.x - x, (m.y - 6) - y
      local d = dx * dx + dy * dy
      if d < bd then best, bd = m, d end
    end
  end
  return best
end

local function bulletHit(b, m)
  b.hit[m] = true
  local dmg = b.dmg
  -- blood pact: bonus per missing HP
  if stats.bloodpact > 0 then dmg = dmg * (1 + stats.bloodpact * (p.maxHp - p.hp)) end
  local crit = random() < stats.crit
  if crit then
    dmg = dmg * stats.critdmg
    addPart(m.x, m.y - 14, 0, -0.6, 6, S.Y)
  end
  damageMob(m, dmg, b.vx, b.vy)
  sfx("hit")

  -- storm coil: chain lightning
  if stats.chain > 0 and random() < stats.chain then
    local from, zapped = m, { [m] = true }
    for _ = 1, 3 do
      local t = nearestMob(from.x, from.y - 6, 60, zapped)
      if not t then break end
      zapped[t] = true
      beams[#beams + 1] = { from.x, from.y - 6, t.x, t.y - 6, 3 }
      damageMob(t, dmg * 0.6)
      from = t
    end
  end

  -- splitter: two smaller bullets fly off sideways
  if stats.split >= 1 and not b.isSplit then
    local a = atan2(b.vy, b.vx)
    local spd = sqrt(b.vx * b.vx + b.vy * b.vy)
    for k = 1, floor(stats.split + 0.5) * 2 do
      local na = a + ((k % 2 == 0) and 0.6 or -0.6) * (1 + floor((k - 1) / 2) * 0.5)
      local nb = { x = b.x, y = b.y, vx = cos(na) * spd, vy = sin(na) * spd, life = 12, dmg = b.dmg * 0.5,
                   pierce = 0, ric = 0, hit = { [m] = true }, col = b.col, isSplit = true }
      bullets[#bullets + 1] = nb
    end
  end
end

local function updateBullets()
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
      if target then
        bulletHit(b, target)
        if b.aoe then explode(b.x, b.y, b.aoe, b.dmg, false, true); dead = true; break end
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
      if b.aoe then explode(b.x, b.y, b.aoe, b.dmg, false, true) end
    end
    if b.aoe and not dead and frame % 2 == 0 then addPart(b.x, b.y, 0, 0, 4, S.D) end
    if dead then removeAt(bullets, i) end
  end
end

---------------------------------------------------------------------- update: player
local function updatePlayer()
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
  p.x, p.y = world.pushOut(p.x + p.vx, p.y + p.vy, 4)
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

  if p.cd > 0 then p.cd = p.cd - 1 end
  if shooting and p.cd <= 0 and #bullets < 300 then fire() end
  if p.iframes > 0 then p.iframes = p.iframes - 1 end

  -- regen / drain
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
local function updateMobs()
  local s = secs()
  for i = #mobs, 1, -1 do
    local m = mobs[i]
    if m.dead then
      removeAt(mobs, i)
    else
      local d = m.def
      local dx, dy = p.x - m.x, p.y - m.y
      local dist = sqrt(dx * dx + dy * dy)
      if dist > 460 then
        if d.boss then
          local x, y = spawnPos()
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

        if d.ranged then
          if dist < 50 then mv = -mv * 0.6 elseif dist < 80 then mv = 0 end
          if dist < 170 and m.cd <= 0 then
            m.cd = random(50, 80)
            local sx, sy = m.x, m.y - 8
            local tx, ty = p.x - sx, p.y - 7 - sy
            local l = sqrt(tx * tx + ty * ty)
            eshots[#eshots + 1] = { x = sx, y = sy, vx = tx / l * 2.6, vy = ty / l * 2.6, life = 90, dmg = 1 + dmgAdd(s) }
          end
        end

        if d.bomb then
          if m.fuse then
            m.fuse = m.fuse - 1
            mv = mv * 0.3
            if m.fuse <= 0 then
              m.exploded = true
              explode(m.x, m.y - 6, 28, 10 * hpMul(s), true, false)
              m.fuse = nil
              killMob(m)
            end
          elseif dist < 18 then
            m.fuse = 16
          end
        end

        if d.boss and m.cd <= 0 then
          m.cd = 100
          for _ = 1, 3 do spawnMob("zombie", m.x + random(-20, 20), m.y + random(-14, 14)) end
        end

        if not m.dead then
          m.x = m.x + nx * mv
          m.y = m.y + ny * mv
          if not d.boss then m.x, m.y = world.pushOut(m.x, m.y, 3) end
          m.moving = mv ~= 0

          -- separation from neighbours
          local r = d.r
          forNear(m.x, m.y, 1, function(o)
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
          end)

          -- contact damage
          if not d.bomb and dist < r + 5 then
            hurtPlayer(d.dmg + dmgAdd(s))
            if d.heavy and dist > 0.01 then
              p.x, p.y = world.pushOut(p.x - nx * 10, p.y - ny * 10, 4)
            end
          end
        end
      end
    end
  end
end

local function updateEShots()
  for i = #eshots, 1, -1 do
    local e = eshots[i]
    e.x, e.y = e.x + e.vx, e.y + e.vy
    e.life = e.life - 1
    local dx, dy = p.x - e.x, (p.y - 7) - e.y
    if dx * dx + dy * dy < 36 then
      hurtPlayer(e.dmg)
      removeAt(eshots, i)
    elseif e.life <= 0 then
      removeAt(eshots, i)
    end
  end
end

---------------------------------------------------------------------- update: passives
local function sawPositions()
  local list = {}
  local n = floor(stats.saws + 0.5)
  for i = 1, n do
    local a = p.sawA + (i - 1) * 2 * pi / n
    list[i] = { p.x + cos(a) * 26, p.y - 6 + sin(a) * 26, a }
  end
  return list
end

local function updatePassives()
  if stats.saws >= 1 then
    p.sawA = p.sawA + 0.18
    for _, sp in ipairs(sawPositions()) do
      forNear(sp[1], sp[2] + 6, 1, function(m)
        local dx, dy = m.x - sp[1], (m.y - 6) - sp[2]
        local r = m.def.r + 3
        if dx * dx + dy * dy <= r * r and (m.sawCd or 0) <= frame then
          m.sawCd = frame + 8
          damageMob(m, 5 * stats.dmg * stats.sawdmg, cos(sp[3]), sin(sp[3]))
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
      local dmg = (2 + stats.aura * 1.5) * stats.dmg
      for _, m in ipairs(mobs) do
        if not m.dead then
          local dx, dy = m.x - p.x, m.y - p.y
          if dx * dx + dy * dy <= (rad + m.def.r) ^ 2 then damageMob(m, dmg) end
        end
      end
    end
  end
end

---------------------------------------------------------------------- update: pickups
local openChest

local function updatePickups()
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
        say("+3 HP", 25, S.R)
        sfx("pick")
      elseif it.kind == "magnet" then
        for _, g in ipairs(gems) do g.pull = true end
        say("MAGNET! All XP incoming", 40, S.C)
        sfx("pick")
      elseif it.kind == "chest" then
        openChest()
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

---------------------------------------------------------------------- update: spawning
local function updateSpawns()
  local s = secs()
  for _, kind in ipairs(SPAWN_ORDER) do
    if not announced[kind] and s >= MOBS[kind].unlock then
      announced[kind] = true
      say(MOBS[kind].intro, 80, S.O)
    end
  end

  spawnTimer = spawnTimer - 1
  if spawnTimer <= 0 then
    spawnTimer = max(5, floor((34 - s / 10) / stats.spawn))
    local batch = 1 + floor(s / 90)
    for _ = 1, batch do
      if #mobs < MAX_MOBS then
        local x, y = spawnPos()
        if x then spawnMob(pickType(s), x, y) end
      end
    end
  end

  if tick >= nextHorde then
    nextHorde = nextHorde + 60 * TPS
    say("A HORDE APPROACHES!", 70, S.R)
    for _ = 1, 16 + floor(s / 30) * 2 do
      if #mobs < MAX_MOBS + 40 then
        local x, y = spawnPos()
        if x then spawnMob((s >= 40 and random() < 0.35) and "ghoul" or "zombie", x, y) end
      end
    end
  end

  if tick >= nextBoss then
    nextBoss = nextBoss + 180 * TPS
    local x, y = spawnPos()
    if x then
      boss = spawnMob("boss", x, y)
      say("!!! THE GRAVE KING RISES !!!", 100, S.R)
      sfx("boss")
    end
  end
end

local function updateFx()
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
  if shake > 0 then shake = shake - 1 end
  if msgTimer > 0 then msgTimer = msgTimer - 1 end
end

---------------------------------------------------------------------- level-up / chest
local function startPick(title, minRarity)
  offers = I.roll(owned, stats.luck, 3, minRarity)
  offerTitle = title
  state = "pick"
  sfx("level")
end

openChest = function()
  p.chests = (p.chests or 0) + 1
  startPick("TREASURE!  Pick a reward", "epic")
end

local function choose(i)
  local it = offers and offers[i]
  if not it then return end
  owned[it.id] = (owned[it.id] or 0) + 1
  if it.weapon then
    p.unlocked[it.weapon] = true
    p.weapon = it.weapon
  end
  recompute()
  if it.heal then p.hp = min(p.maxHp, p.hp + it.heal) end
  say(it.name .. "!", 40, P.slot[I.RARITY[it.rarity].col])
  if offerTitle:sub(1, 5) == "LEVEL" then p.pending = p.pending - 1 end
  if p.pending > 0 then
    startPick("LEVEL UP!  Level " .. (p.level - p.pending + 1))
  else
    offers = nil
    state = "play"
    p.iframes = max(p.iframes, 20)
  end
end

gameOver = function()
  state = "dead"
  deadTimer = 0
  save.runs = (save.runs or 0) + 1
  if score > (save.best or 0) then save.best = score; newBest = true end
  if secs() > (save.bestTime or 0) then save.bestTime = floor(secs()) end
  writeSave()
end

local function update()
  tick = tick + 1
  buildGrid()
  updatePlayer()
  updateBullets()
  updateMobs()
  updateEShots()
  updatePassives()
  updatePickups()
  updateSpawns()
  updateFx()
  if state == "play" and p.pending > 0 then startPick("LEVEL UP!  Level " .. (p.level - p.pending + 1)) end
end

---------------------------------------------------------------------- render
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
  for i = 0, n do
    scr.pixel(x1 + dx * i / n - camX, y1 + dy * i / n - camY, col)
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

local function renderWorld()
  local sx = shake > 0 and random(-shake, shake) or 0
  local sy = shake > 0 and random(-shake, shake) or 0
  camX = floor(p.x + 0.5) - floor(PW / 2) + sx
  camY = floor(p.y - 7 + 0.5) - floor(PH / 2) + sy

  world.drawGround(scr, camX, camY)

  -- flat things on the ground
  for _, g in ipairs(gems) do
    scr.sprite(g.v >= 4 and spr.xp_big or spr.xp_orb, g.x - 2 - camX, g.y - 2 - camY)
  end
  for _, it in ipairs(pickups) do
    if it.ttl > 5 * TPS or frame % 6 < 3 then
      local sp = spr[it.kind]
      scr.sprite(sp, it.x - sp.w / 2 - camX, it.y - sp.h - camY + ((frame % 20 < 10) and 0 or -1))
    end
  end

  -- aura ring
  if stats.aura >= 1 and p.auraFlash > 0 then
    local rad = (20 + stats.aura * 8) * stats.area
    local n = floor(rad * 2)
    for i = 1, n do
      local a = i / n * 2 * pi
      scr.pixel(p.x + cos(a) * rad - camX, p.y - 6 + sin(a) * rad - camY, S.g)
    end
  end

  -- depth-sorted sprites
  nDraw = 0
  world.propsInView(camX, camY, PW, PH, addDraw)
  for _, m in ipairs(mobs) do
    local sp = spr[m.def.spr]
    local x, y = m.x - sp.w / 2, m.y - sp.h + 1
    if x + sp.w > camX and x < camX + PW and y + sp.h > camY and y < camY + PH then
      local bob = (m.moving and (frame + m.phase) % 12 < 6) and -1 or 0
      local tint = nil
      if m.flash > 0 then tint = S.W end
      if m.fuse and m.fuse % 4 < 2 then tint = S.W end
      addDraw(sp, x, y + bob, m.flip, tint, m.y)
    end
  end
  local psp = spr.player
  local pbob = (p.moving and frame % 8 < 4) and -1 or 0
  local ptint = (p.iframes > 0 and frame % 4 < 2) and S.R or nil
  addDraw(psp, floor(p.x + 0.5) - 6, floor(p.y + 0.5) - psp.h + 1 + pbob, p.flip, ptint, p.y)
  for i = nDraw + 1, #drawList do drawList[i] = nil end
  table.sort(drawList, zsort)
  for i = 1, nDraw do
    local e = drawList[i]
    scr.sprite(e[1], e[2] - camX, e[3] - camY, e[4], e[5])
  end

  -- projectiles
  for _, b in ipairs(bullets) do
    local bx, by = b.x - camX, b.y - camY
    scr.pixel(bx, by, b.col)
    if b.aoe then
      scr.pixel(bx - b.vx * 0.5, by - b.vy * 0.5, S.O)
    else
      scr.pixel(bx - b.vx * 0.3, by - b.vy * 0.3, b.col)
    end
  end
  for _, e in ipairs(eshots) do
    local l = sqrt(e.vx * e.vx + e.vy * e.vy)
    local ux, uy = e.vx / l, e.vy / l
    scr.pixel(e.x - camX, e.y - camY, S.A)
    scr.pixel(e.x - ux - camX, e.y - uy - camY, S.B)
    scr.pixel(e.x - ux * 2 - camX, e.y - uy * 2 - camY, S.B)
    scr.pixel(e.x - ux * 3 - camX, e.y - uy * 3 - camY, S.W)
  end

  -- saws
  if stats.saws >= 1 then
    local ss = (frame % 4 < 2) and spr.saw1 or spr.saw2
    for _, sp in ipairs(sawPositions()) do scr.sprite(ss, sp[1] - 2 - camX, sp[2] - 2 - camY) end
  end

  -- lightning + particles
  for _, b in ipairs(beams) do
    line(b[1], b[2], b[3] + random(-1, 1), b[4], (b[5] % 2 == 0) and S.Y or S.W)
  end
  for _, q in ipairs(parts) do scr.pixel(q.x - camX, q.y - camY, q.col) end
end

local function renderHUD()
  -- row 1: hp + stats
  box(1, 1, CW, 1, S.K)
  local filled = ceil(p.hp / p.maxHp * 20)
  T(2, 1, "HP", S.W)
  local bar = ""
  local fgs, bgs = "", ""
  for i = 1, 20 do
    bar = bar .. " "
    bgs = bgs .. G.HEX[i <= filled and S.R or S.D]
    fgs = fgs .. "0"
  end
  T(5, 1, bar, fgs, bgs)
  local info = ("%d/%d   LV %d   %s   Kills %d   Score %d"):format(ceil(p.hp), p.maxHp, p.level, fmtTime(secs()), kills, score)
  T(27, 1, info, S.W)
  local best = "Best " .. (save.best or 0)
  T(CW - #best, 1, best, S.A)

  -- row 2: xp bar with label
  local frac = min(1, p.xp / p.xpNext)
  local fillW = floor(frac * CW)
  local label = ("LEVEL %d   %d / %d XP"):format(p.level, floor(p.xp), p.xpNext)
  local lx = floor((CW - #label) / 2) + 1
  local chars, fg2, bg2 = {}, {}, {}
  for x = 1, CW do
    local on = x <= fillW
    local ch = " "
    if x >= lx and x < lx + #label then ch = label:sub(x - lx + 1, x - lx + 1) end
    chars[x] = ch
    fg2[x] = on and "f" or "8"
    bg2[x] = G.HEX[on and S.C or S.D]
  end
  T(1, 2, table.concat(chars), table.concat(fg2), table.concat(bg2))

  -- boss bar
  local row = 4
  if boss and not boss.dead then
    local bw = min(CW - 30, 100)
    local bx = floor((CW - bw) / 2) + 1
    T(bx - 13, 3, " GRAVE KING ", S.W, S.R)
    local bf = floor(max(0, boss.hp) / boss.maxHp * bw)
    T(bx, 3, (" "):rep(bw), S.W, S.D)
    if bf > 0 then T(bx, 3, (" "):rep(bf), S.W, S.R) end
    row = 5
  end

  -- message
  if msgTimer > 0 and msg ~= "" then center(row, " " .. msg .. " ", msgCol, S.K) end

  -- bottom row: weapons
  box(1, CH, CW, 1, S.K)
  local x = 2
  for i = 1, 4 do
    local lbl = " " .. i .. " " .. (p.unlocked[i] and WEAPONS[i].name or "-----") .. " "
    if i == p.weapon then T(x, CH, lbl, S.K, S.Y)
    else T(x, CH, lbl, p.unlocked[i] and S.W or S.D, S.K) end
    x = x + #lbl + 1
  end
  T(CW - 18, CH, "P pause / build", S.A)
end

local function statLines()
  local st = stats
  local L = {
    ("Damage      x%.2f"):format(st.dmg),
    ("Fire rate   x%.2f"):format(st.rate),
    ("Projectiles +%d"):format(floor(st.proj + 0.5)),
    ("Pierce      %d"):format(floor(st.pierce + 0.5)),
    ("Crit        %d%%  x%.2f"):format(floor(st.crit * 100 + 0.5), st.critdmg),
    ("Move speed  x%.2f"):format(st.speed),
    ("Max HP      %d"):format(p.maxHp),
    ("Armor       -%d%% dmg"):format(floor(min(0.6, st.armor * 0.15) * 100 + 0.5)),
    ("Dodge       %d%%"):format(floor(st.dodge * 100 + 0.5)),
    ("XP gain     x%.2f"):format(st.xp),
    ("Luck        %.1f"):format(st.luck),
    ("Mob spawns  x%.2f"):format(st.spawn),
  }
  return L
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

local function renderOverlay()
  if state == "title" then
    local w, h = 64, 24
    local x0, y0 = floor((CW - w) / 2) + 1, floor((CH - h) / 2) + 1
    box(x0 - 1, y0 - 1, w + 2, h + 2, S.D)
    box(x0, y0, w, h, S.K)
    center(y0 + 2, "D  E  A  D     Z  O  N  E", S.R)
    center(y0 + 3, "survive the endless undead", S.A)
    local lines = {
      "WASD        move",
      "SPACE       shoot (hold)",
      "ARROWS      aim + shoot",
      "1 2 3 4     switch weapon",
      "1 2 3       pick item on level up",
      "R           reroll items",
      "P           pause / see your build",
    }
    for i, l in ipairs(lines) do T(x0 + 14, y0 + 5 + i, l, S.W) end
    center(y0 + 15, ("Best score %d    Longest run %s    Runs %d"):format(save.best or 0, fmtTime(save.bestTime or 0), save.runs or 0), S.Y)
    if frame % 20 < 14 then center(y0 + 18, "Press SPACE to start", S.g) end
    center(y0 + 21, "Q quit", S.A)

  elseif state == "pick" and offers then
    local cardW = min(44, floor((CW - 12) / 3))
    local w = cardW * 3 + 8
    local h = 24
    local x0, y0 = floor((CW - w) / 2) + 1, floor((CH - h) / 2) + 1
    box(x0 - 1, y0 - 1, w + 2, h + 2, S.Y)
    box(x0, y0, w, h, S.K)
    center(y0 + 1, offerTitle, S.Y)
    for i, it in ipairs(offers) do
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
    end
    local foot = "1 2 3  pick"
    if rerolls > 0 then foot = foot .. "        R  reroll (" .. rerolls .. " left)" end
    center(y0 + 22, foot, S.W)

  elseif state == "paused" then
    local w, h = 80, 26
    local x0, y0 = floor((CW - w) / 2) + 1, floor((CH - h) / 2) + 1
    box(x0 - 1, y0 - 1, w + 2, h + 2, S.D)
    box(x0, y0, w, h, S.K)
    center(y0 + 1, "PAUSED", S.Y)
    T(x0 + 3, y0 + 3, "YOUR STATS", S.A)
    for i, l in ipairs(statLines()) do T(x0 + 3, y0 + 4 + i, l, S.W) end
    T(x0 + 42, y0 + 3, "YOUR ITEMS", S.A)
    local items = ownedList()
    if #items == 0 then T(x0 + 42, y0 + 5, "nothing yet", S.D) end
    for i, e in ipairs(items) do
      if i <= 18 then T(x0 + 42, y0 + 4 + i, e[1], e[2]) end
    end
    center(y0 + 24, "P / SPACE resume      Q end run", S.W)

  elseif state == "dead" then
    local w, h = 60, 20
    local x0, y0 = floor((CW - w) / 2) + 1, floor((CH - h) / 2) + 1
    box(x0 - 1, y0 - 1, w + 2, h + 2, S.R)
    box(x0, y0, w, h, S.K)
    center(y0 + 2, "Y O U   D I E D", S.R)
    center(y0 + 5, "Survived " .. fmtTime(secs()), S.W)
    center(y0 + 6, ("Level %d    Kills %d"):format(p.level, kills), S.W)
    center(y0 + 8, "Score " .. score, S.Y)
    if newBest then
      if frame % 10 < 6 then center(y0 + 9, "NEW BEST!", S.g) end
    else
      center(y0 + 9, "Best " .. (save.best or 0), S.A)
    end
    local items = ownedList()
    local names = {}
    for i, e in ipairs(items) do if i <= 6 then names[#names + 1] = e[1] end end
    if #names > 0 then center(y0 + 12, table.concat(names, ", "):sub(1, w - 4), S.A) end
    if deadTimer > 30 then center(y0 + 16, "SPACE new run      Q title", S.g) end
  end
end

local function render()
  if state == "title" then
    -- slow drift over the field behind the title
    p.x = p.x + 0.6
  end
  renderWorld()
  if state ~= "title" then renderHUD() end
  renderOverlay()
  scr.present()
end

---------------------------------------------------------------------- input
local NUM = { [keys.one] = 1, [keys.two] = 2, [keys.three] = 3, [keys.four] = 4 }

local function onKey(k)
  if state == "title" then
    if k == keys.space or k == keys.enter then newRun(); state = "play"
    elseif k == keys.q then running = false end
  elseif state == "play" then
    if k == keys.p then state = "paused"
    elseif NUM[k] then
      local n = NUM[k]
      if p.unlocked[n] then p.weapon = n; say(WEAPONS[n].name, 25, S.W)
      else say("Weapon " .. n .. " is locked - find it in level-up items", 40, S.A) end
    end
  elseif state == "pick" then
    local n = NUM[k]
    if n and n <= 3 then choose(n)
    elseif k == keys.r and rerolls > 0 then
      rerolls = rerolls - 1
      offers = I.roll(owned, stats.luck, 3, offerTitle:sub(1, 5) == "TREAS" and "epic" or nil)
    end
  elseif state == "paused" then
    if k == keys.p or k == keys.space then state = "play"
    elseif k == keys.q then gameOver() end
  elseif state == "dead" then
    if deadTimer > 30 and (k == keys.space or k == keys.enter) then newRun(); state = "play"
    elseif k == keys.q then newRun(); state = "title" end
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
    { "1-4      weapons", colours.white },
    { "1-3      pick item,  R reroll", colours.white },
    { "P        pause / build", colours.white },
  }
  for i, l in ipairs(lines) do
    native.setCursorPos(2, i + 1)
    native.setTextColour(l[2])
    native.write(l[1])
  end
end

---------------------------------------------------------------------- main loop
local function main()
  loadSave()
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
      if state == "dead" then deadTimer = deadTimer + 1 end
      render()
    elseif e == "key" then
      held[ev[2]] = true
      if not ev[3] then onKey(ev[2]) end
    elseif e == "key_up" then
      held[ev[2]] = nil
    elseif e == "terminate" then
      running = false
    end
  end
end

local ok, err = pcall(main)
P.restore(out)
out.setBackgroundColour(colours.black)
out.clear()
if mon then mon.setTextScale(1) end
native.setBackgroundColour(colours.black)
native.setTextColour(colours.white)
native.clear()
native.setCursorPos(1, 1)
if not ok then printError(err) end
print("Thanks for playing DEAD ZONE!")
