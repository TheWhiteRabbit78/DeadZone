-- DEAD ZONE world: endless grass field with sparse trees and rocks.
-- Ground decoration (tufts, flowers) is drawn as tiny sprites so the camera
-- can move 1 pixel at a time. Props block the player and push mobs around.

local G = require("dz.gfx")
local P = require("dz.palette")

local floor, sqrt, sin = math.floor, math.sqrt, math.sin

local W = {}

local RW, RH = 48, 40          -- one prop chance per region of this size
local DECO_GRID = 8

function W.new(spr, seed)
  local self = {}
  local s = P.slot
  self.plain = G.pattern({ s.G, s.G, s.G, s.G, s.G, s.G })

  local DECO = {
    G.compile({ "g.g", ".g." }),
    G.compile({ "g..", ".g.", ".g." }),
    G.compile({ ".g", "g.", "g." }),
    G.compile({ "Y" }),
    G.compile({ "R" }),
  }

  local function hash(x, y, k)
    local n = sin(x * 127.1 + y * 311.7 + (seed + k) * 74.7) * 43758.5453
    return n - floor(n)
  end

  -- ground decoration ------------------------------------------------------
  local decoCache, decoRows = {}, 0
  local function decoAt(gx, gy)
    local row = decoCache[gy]
    if not row then
      if decoRows > 3000 then decoCache, decoRows = {}, 0 end
      row = {}
      decoCache[gy] = row
      decoRows = decoRows + 1
    end
    local d = row[gx]
    if d == nil then
      local r = hash(gx, gy, 0)
      d = false
      if r < 0.30 then
        local kind = (r < 0.28) and (1 + floor(r * 100) % 3) or (r < 0.29 and 4 or 5)
        d = { DECO[kind], gx * DECO_GRID + floor(hash(gx, gy, 1) * 6), gy * DECO_GRID + floor(hash(gx, gy, 2) * 6) }
      end
      row[gx] = d
    end
    return d
  end

  function self.drawGround(scr, camX, camY)
    local plain = self.plain
    scr.fillBase(function() return plain end)
    for gy = floor(camY / DECO_GRID) - 1, floor((camY + scr.PH) / DECO_GRID) do
      for gx = floor(camX / DECO_GRID) - 1, floor((camX + scr.PW) / DECO_GRID) do
        local d = decoAt(gx, gy)
        if d then scr.sprite(d[1], d[2] - camX, d[3] - camY) end
      end
    end
  end

  -- props --------------------------------------------------------------------
  -- returns prop table or false. Props are cached per region.
  -- prop = { spr, x, y (top-left), bx, by (blocking circle centre), br, z (depth) }
  local propCache, propRows = {}, 0
  local function propAt(rx, ry)
    local row = propCache[ry]
    if not row then
      if propRows > 2000 then propCache, propRows = {}, 0 end
      row = {}
      propCache[ry] = row
      propRows = propRows + 1
    end
    local pr = row[rx]
    if pr == nil then
      pr = false
      local r = hash(rx, ry, 11)
      if r < 0.22 then
        local kind = (r < 0.09) and "oak" or (r < 0.17 and "pine" or "rock")
        local sp = spr[kind]
        local x = rx * RW + floor(hash(rx, ry, 12) * (RW - sp.w))
        local y = ry * RH + floor(hash(rx, ry, 13) * (RH - sp.h))
        local bx, by, br
        if kind == "rock" then
          bx, by, br = x + sp.w / 2, y + sp.h - 3, 5
        else
          bx, by, br = x + sp.w / 2, y + sp.h - 2, (kind == "oak") and 3 or 2
        end
        -- keep the spawn area clear
        if bx * bx + by * by > 70 * 70 then
          pr = { spr = sp, x = x, y = y, bx = bx, by = by, br = br, z = y + sp.h }
        end
      end
      row[rx] = pr
    end
    return pr
  end

  -- props overlapping the view, appended into list as draw entries
  function self.propsInView(camX, camY, PW, PH, add)
    for ry = floor((camY - 24) / RH), floor((camY + PH) / RH) do
      for rx = floor((camX - 24) / RW), floor((camX + PW) / RW) do
        local pr = propAt(rx, ry)
        if pr then add(pr.spr, pr.x, pr.y, false, nil, pr.z) end
      end
    end
  end

  -- push a circle (x, y, r) out of any prop; returns new x, y
  function self.pushOut(x, y, r)
    local rx0, ry0 = floor(x / RW), floor(y / RH)
    for ry = ry0 - 1, ry0 + 1 do
      for rx = rx0 - 1, rx0 + 1 do
        local pr = propAt(rx, ry)
        if pr then
          local dx, dy = x - pr.bx, y - pr.by
          local min = r + pr.br
          local d2 = dx * dx + dy * dy
          if d2 < min * min then
            local d = sqrt(d2)
            if d < 0.01 then dx, dy, d = 1, 0, 1 end
            x = pr.bx + dx / d * min
            y = pr.by + dy / d * min
          end
        end
      end
    end
    return x, y
  end

  return self
end

return W
