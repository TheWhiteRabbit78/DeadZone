--[[
  DEAD ZONE - pixel engine SPEED TEST
  Scrolling pixel world + sprites on the monitor wall.

  Controls (keep the computer screen open):
    WASD   move           SPACE  shoot
    E / Q  +10 / -10 mobs
    F      toggle 20 / 10 FPS cap
    X      quit

  Tell Claude: FPS, frame ms, and server TPS (/spark tps or /neoforge tps)
  with 30 mobs and with 100+ mobs.
]]

local dir = fs.getDir(shell.getRunningProgram())
package.path = "/" .. dir .. "/?.lua;" .. package.path

local P = require("dz.palette")
local G = require("dz.gfx")
local SPR = require("dz.sprites")

local floor, sqrt, random, abs = math.floor, math.sqrt, math.random, math.abs
local sin = math.sin

---------------------------------------------------------------- display
local mon = peripheral.find("monitor", function(_, m) return m.isColour() end)
if not mon then error("No Advanced Monitor found", 0) end
mon.setTextScale(0.5)
P.apply(mon)
local scr = G.new(mon)
local PW, PH, CW, CH = scr.PW, scr.PH, scr.CW, scr.CH

---------------------------------------------------------------- sprites
local spr = {}
for name, rows in pairs(SPR) do spr[name] = G.compile(rows) end

---------------------------------------------------------------- ground (cell-based, infinite)
local s = P.slot
local Gc, gc = s.G, s.g
local PAT = {
  G.pattern({ Gc, Gc, Gc, Gc, Gc, Gc }),        -- plain
  G.pattern({ Gc, Gc, gc, Gc, Gc, gc }),        -- tuft
  G.pattern({ Gc, Gc, Gc, gc, gc, Gc }),        -- tuft
  G.pattern({ Gc, gc, Gc, Gc, gc, Gc }),        -- tuft
  G.pattern({ Gc, Gc, Gc, s.Y, Gc, Gc }),       -- yellow flower
  G.pattern({ Gc, Gc, s.R, Gc, Gc, Gc }),       -- red flower
}
local seed = random(1, 9999)

local function hash(x, y, k)
  local n = sin(x * 127.1 + y * 311.7 + (seed + k) * 74.7) * 43758.5453
  return n - floor(n)
end

local ground = {}
local function groundAt(wx, wy)
  local row = ground[wy]
  if not row then row = {}; ground[wy] = row end
  local p = row[wx]
  if not p then
    local r = hash(wx, wy, 0)
    if r < 0.025 then p = PAT[2]
    elseif r < 0.05 then p = PAT[3]
    elseif r < 0.07 then p = PAT[4]
    elseif r < 0.073 then p = PAT[5]
    elseif r < 0.076 then p = PAT[6]
    else p = PAT[1] end
    row[wx] = p
  end
  return p
end

---------------------------------------------------------------- props (trees/rocks), one chance per region
local RW, RH = 40, 36
local function regionProp(rx, ry)
  local r = hash(rx, ry, 11)
  if r > 0.3 then return nil end
  local x = rx * RW + floor(hash(rx, ry, 12) * (RW - 16))
  local y = ry * RH + floor(hash(rx, ry, 13) * (RH - 16))
  if abs(x) < 60 and abs(y) < 50 then return nil end -- clear spawn
  local kind = (r < 0.13) and "oak" or (r < 0.24 and "pine" or "rock")
  return kind, x, y
end

---------------------------------------------------------------- entities
local player = { x = 0, y = 0, vx = 0, vy = 0, flip = false, fx = 1, fy = 0, cd = 0 }
local mobs, bullets = {}, {}
local MOB_KINDS = { "zombie", "zombie", "ghoul", "skeleton", "brute", "bomb_imp" }

local function addMobs(n)
  for _ = 1, n do
    local a = random() * math.pi * 2
    local d = 120 + random() * 80
    mobs[#mobs + 1] = {
      x = player.x + math.cos(a) * d, y = player.y + math.sin(a) * d,
      kind = MOB_KINDS[random(#MOB_KINDS)], speed = 0.4 + random() * 0.5, flip = false, flash = 0,
    }
  end
end
addMobs(30)

local held = {}
local running = true
local frameDelay = 0.05

---------------------------------------------------------------- update
local function update()
  -- smooth player movement: accelerate toward target velocity
  local ix, iy = 0, 0
  if held[keys.a] then ix = ix - 1 end
  if held[keys.d] then ix = ix + 1 end
  if held[keys.w] then iy = iy - 1 end
  if held[keys.s] then iy = iy + 1 end
  local MAX = 1.9
  if ix ~= 0 and iy ~= 0 then ix, iy = ix * 0.7071, iy * 0.7071 end
  player.vx = player.vx + (ix * MAX - player.vx) * 0.35
  player.vy = player.vy + (iy * MAX - player.vy) * 0.35
  player.x = player.x + player.vx
  player.y = player.y + player.vy
  if ix ~= 0 or iy ~= 0 then player.fx, player.fy = ix, iy end
  if ix < 0 then player.flip = true elseif ix > 0 then player.flip = false end

  -- shooting
  if player.cd > 0 then player.cd = player.cd - 1 end
  if held[keys.space] and player.cd <= 0 then
    player.cd = 4
    bullets[#bullets + 1] = { x = player.x + 6, y = player.y + 8, vx = player.fx * 6, vy = player.fy * 6, life = 30 }
  end
  for i = #bullets, 1, -1 do
    local b = bullets[i]
    b.x, b.y, b.life = b.x + b.vx, b.y + b.vy, b.life - 1
    if b.life <= 0 then table.remove(bullets, i) end
  end

  -- mobs walk at the player (no collision in the speed test)
  for _, m in ipairs(mobs) do
    local dx, dy = player.x - m.x, player.y - m.y
    local d = sqrt(dx * dx + dy * dy)
    if d > 8 then
      m.x = m.x + dx / d * m.speed
      m.y = m.y + dy / d * m.speed
    end
    m.flip = dx < 0
    if m.flash > 0 then m.flash = m.flash - 1 end
    if d > 400 then -- respawn far ones around the player
      local a = random() * math.pi * 2
      m.x, m.y = player.x + math.cos(a) * 180, player.y + math.sin(a) * 140
    end
  end
  -- bullets flash mobs they pass through (visual only)
  for _, b in ipairs(bullets) do
    for _, m in ipairs(mobs) do
      if abs(b.x - m.x - 5) < 6 and abs(b.y - m.y - 7) < 7 then m.flash = 2 end
    end
  end
end

---------------------------------------------------------------- render
local camX, camY = 0, 0
local drawList = {}

local function render()
  -- camera centred on player, snapped to whole cells (2x3 px) so the ground can be pre-encoded
  local tx = player.x + 6 - PW / 2
  local ty = player.y + 7 - PH / 2
  camX, camY = floor(tx / 2) * 2, floor(ty / 3) * 3
  local ccx, ccy = camX / 2, camY / 3

  scr.fillBase(function(cx, cy) return groundAt(ccx + cx, ccy + cy) end)

  -- collect things to draw, sorted by their feet (y + height) for depth
  local n = 0
  local rx0, rx1 = floor((camX - 20) / RW), floor((camX + PW) / RW)
  local ry0, ry1 = floor((camY - 20) / RH), floor((camY + PH) / RH)
  for ry = ry0, ry1 do
    for rx = rx0, rx1 do
      local kind, x, y = regionProp(rx, ry)
      if kind then
        n = n + 1
        local e = drawList[n] or {}
        drawList[n] = e
        e.s, e.x, e.y, e.flip, e.tint, e.z = spr[kind], x, y, false, nil, y + spr[kind].h
      end
    end
  end
  for _, m in ipairs(mobs) do
    local sp = spr[m.kind]
    if m.x + sp.w > camX and m.x < camX + PW and m.y + sp.h > camY and m.y < camY + PH then
      n = n + 1
      local e = drawList[n] or {}
      drawList[n] = e
      e.s, e.x, e.y, e.flip, e.tint, e.z = sp, m.x, m.y, m.flip, (m.flash > 0) and s.W or nil, m.y + sp.h
    end
  end
  n = n + 1
  local e = drawList[n] or {}
  drawList[n] = e
  e.s, e.x, e.y, e.flip, e.tint, e.z = spr.player, player.x, player.y, player.flip, nil, player.y + spr.player.h
  for i = n + 1, #drawList do drawList[i] = nil end
  table.sort(drawList, function(a, b) return a.z < b.z end)

  for i = 1, n do
    local d = drawList[i]
    scr.sprite(d.s, d.x - camX, d.y - camY, d.flip, d.tint)
  end
  for _, b in ipairs(bullets) do
    scr.sprite(spr.bullet, b.x - camX, b.y - camY)
  end
end

---------------------------------------------------------------- stats + main loop
local fps, frames, lastSec = 0, 0, os.epoch("utc")
local workMs, workAcc, workN = 0, 0, 0

local function drawTerminal()
  term.setBackgroundColour(colours.black)
  term.clear()
  term.setCursorPos(1, 1)
  term.setTextColour(colours.red)
  print("DEAD ZONE - speed test")
  term.setTextColour(colours.white)
  print("")
  print("FPS:        " .. fps .. "   (cap " .. floor(1 / frameDelay + 0.5) .. ")")
  print("Frame work: " .. workMs .. " ms")
  print("Mobs:       " .. #mobs)
  print("Cells drawn by sprites: " .. scr.stats.dirty)
  print("Rows sent:  " .. scr.stats.rows .. " / " .. CH)
  print("")
  term.setTextColour(colours.lightGrey)
  print("WASD move   SPACE shoot")
  print("E / Q  +10 / -10 mobs")
  print("F      20 / 10 FPS cap")
  print("X      quit")
  print("")
  print("Also check server TPS:")
  print("/spark tps  or  /neoforge tps")
end

local function main()
  drawTerminal()
  local timer = os.startTimer(frameDelay)
  while running do
    local ev = { os.pullEventRaw() }
    local e = ev[1]
    if e == "timer" and ev[2] == timer then
      timer = os.startTimer(frameDelay)
      local t0 = os.epoch("utc")
      update()
      render()
      scr.text(1, 1, (" FPS %d  frame %dms  mobs %d  cells %d "):format(fps, workMs, #mobs, scr.stats.dirty), s.W, s.K)
      scr.present()
      local dt = os.epoch("utc") - t0
      workAcc, workN = workAcc + dt, workN + 1
      frames = frames + 1
      local now = os.epoch("utc")
      if now - lastSec >= 1000 then
        fps = frames
        workMs = floor(workAcc / math.max(1, workN) + 0.5)
        frames, workAcc, workN, lastSec = 0, 0, 0, now
        drawTerminal()
      end
    elseif e == "key" then
      held[ev[2]] = true
      if not ev[3] then
        if ev[2] == keys.e then addMobs(10)
        elseif ev[2] == keys.q then for _ = 1, math.min(10, #mobs) do table.remove(mobs) end
        elseif ev[2] == keys.f then frameDelay = (frameDelay == 0.05) and 0.1 or 0.05
        elseif ev[2] == keys.x then running = false end
      end
    elseif e == "key_up" then
      held[ev[2]] = nil
    elseif e == "terminate" then
      running = false
    end
  end
end

local ok, err = pcall(main)
P.restore(mon)
mon.setBackgroundColour(colours.black)
mon.clear()
mon.setTextScale(1)
term.setBackgroundColour(colours.black)
term.setTextColour(colours.white)
term.clear()
term.setCursorPos(1, 1)
if not ok then printError(err) end
print("Speed test ended.")
