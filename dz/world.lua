-- DEAD ZONE world: endless grass field with sparse trees, rocks, lakes and outpost sites.
--
-- Ground decoration (tufts, flowers) is drawn as tiny sprites so the camera
-- can move 1 pixel at a time. Lakes are drawn per text cell: cells fully in
-- water / fully on grass use a ready pattern, cells on the shoreline are
-- worked out pixel by pixel, so the shore moves smoothly with the camera.
-- Props and lakes block walking; bullets fly over water.

local G = require("dz.gfx")
local P = require("dz.palette")

local floor, sqrt, sin, min, max = math.floor, math.sqrt, math.sin, math.min, math.max

local W = {}

local RW, RH = 48, 40             -- one prop chance per region of this size
local DECO_GRID = 8
local LW, LH = 360, 300           -- one lake chance per region of this size
local OW, OH = 420, 340           -- one outpost chance per region of this size

function W.new(spr, seed)
  local self = {}
  local s = P.slot
  local plain = G.pattern({ s.G, s.G, s.G, s.G, s.G, s.G })
  local water = G.pattern({ s.U, s.U, s.U, s.U, s.U, s.U })
  self.plain = plain

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

  -- lakes ----------------------------------------------------------------------
  -- lake = { circles = { {x, y, r}, ... }, x0, y0, x1, y1 (bbox incl. shore), lilies, reeds }
  local lakeCache = {}
  local function lakeAt(lx, ly)
    local key = lx * 65536 + ly
    local lk = lakeCache[key]
    if lk ~= nil then return lk end
    lk = false
    if hash(lx, ly, 31) < 0.35 then
      local cx = lx * LW + 70 + floor(hash(lx, ly, 32) * (LW - 140))
      local cy = ly * LH + 70 + floor(hash(lx, ly, 33) * (LH - 140))
      if cx * cx + cy * cy > 200 * 200 then
        lk = { circles = {} }
        local n = 2 + floor(hash(lx, ly, 34) * 3)
        local x0, y0, x1, y1 = 1e9, 1e9, -1e9, -1e9
        for i = 1, n do
          local a = hash(lx, ly, 40 + i) * 6.283
          local d = (i == 1) and 0 or (14 + hash(lx, ly, 50 + i) * 22)
          local r = 22 + floor(hash(lx, ly, 60 + i) * 26)
          local c = { cx + math.cos(a) * d, cy + math.sin(a) * d, r }
          lk.circles[i] = c
          x0, y0 = min(x0, c[1] - r - 4), min(y0, c[2] - r - 4)
          x1, y1 = max(x1, c[1] + r + 4), max(y1, c[2] + r + 4)
        end
        lk.x0, lk.y0, lk.x1, lk.y1 = x0, y0, x1, y1
        -- lily pads inside, reeds on the shore
        lk.lilies, lk.reeds = {}, {}
        for i = 1, 6 do
          local c = lk.circles[1 + (i % n)]
          local a, d = hash(lx, ly, 70 + i) * 6.283, hash(lx, ly, 80 + i) * (c[3] - 8)
          lk.lilies[i] = { c[1] + math.cos(a) * d, c[2] + math.sin(a) * d }
        end
        for i = 1, 12 do
          local c = lk.circles[1 + (i % n)]
          local a = hash(lx, ly, 90 + i) * 6.283
          local rx, ry = c[1] + math.cos(a) * (c[3] + 4), c[2] + math.sin(a) * (c[3] + 4)
          -- only where it's actually shore (not inside another part of the lake)
          local inside = false
          for _, c2 in ipairs(lk.circles) do
            if (rx - c2[1]) ^ 2 + (ry - c2[2]) ^ 2 < (c2[3] + 2) ^ 2 then inside = true end
          end
          if not inside then lk.reeds[#lk.reeds + 1] = { rx, ry } end
        end
      end
    end
    lakeCache[key] = lk
    return lk
  end

  -- distance from (x, y) to the lake edge: < 0 inside water
  local function lakeEdge(lk, x, y)
    local best = 1e9
    for _, c in ipairs(lk.circles) do
      local dx, dy = x - c[1], y - c[2]
      local d = sqrt(dx * dx + dy * dy) - c[3]
      if d < best then best = d end
    end
    return best
  end

  local function lakesNear(x, y, out)
    local lx, ly = floor(x / LW), floor(y / LH)
    local n = 0
    for yy = ly - 1, ly + 1 do
      for xx = lx - 1, lx + 1 do
        local lk = lakeAt(xx, yy)
        if lk then n = n + 1; out[n] = lk end
      end
    end
    for i = n + 1, #out do out[i] = nil end
    return n
  end

  local tmpLakes = {}
  -- edge distance to the nearest lake (large if none)
  function self.waterEdge(x, y)
    local n = lakesNear(x, y, tmpLakes)
    local best = 1e9
    for i = 1, n do
      local lk = tmpLakes[i]
      if x > lk.x0 - 40 and x < lk.x1 + 40 and y > lk.y0 - 40 and y < lk.y1 + 40 then
        local d = lakeEdge(lk, x, y)
        if d < best then best = d end
      end
    end
    return best
  end
  local waterEdge = self.waterEdge

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
        local x, y = gx * DECO_GRID + floor(hash(gx, gy, 1) * 6), gy * DECO_GRID + floor(hash(gx, gy, 2) * 6)
        if waterEdge(x, y) > 4 then d = { DECO[kind], x, y } end
      end
      row[gx] = d
    end
    return d
  end

  -- shoreline cells: pattern cache by colour combo
  local patCache = {}
  local function shorePattern(c1, c2, c3, c4, c5, c6)
    local key = ((((c1 * 16 + c2) * 16 + c3) * 16 + c4) * 16 + c5) * 16 + c6
    local pt = patCache[key]
    if not pt then
      pt = G.pattern({ c1, c2, c3, c4, c5, c6 })
      patCache[key] = pt
    end
    return pt
  end
  local function subColour(lk, x, y)
    local d = lakeEdge(lk, x, y)
    if d < 0 then return s.U elseif d < 2.5 then return s.S else return s.G end
  end

  local viewLakes = {}
  function self.drawGround(scr, camX, camY)
    -- lakes overlapping the view
    local nv = 0
    for ly = floor((camY - 80) / LH), floor((camY + scr.PH + 80) / LH) do
      for lx = floor((camX - 80) / LW), floor((camX + scr.PW + 80) / LW) do
        local lk = lakeAt(lx, ly)
        if lk and lk.x1 > camX and lk.x0 < camX + scr.PW and lk.y1 > camY and lk.y0 < camY + scr.PH then
          nv = nv + 1
          viewLakes[nv] = lk
        end
      end
    end
    for i = nv + 1, #viewLakes do viewLakes[i] = nil end

    if nv == 0 then
      scr.fillBase(function() return plain end)
    else
      scr.fillBase(function(cx, cy)
        local wx, wy = camX + cx * 2, camY + cy * 3
        for i = 1, nv do
          local lk = viewLakes[i]
          if wx + 2 > lk.x0 and wx < lk.x1 and wy + 3 > lk.y0 and wy < lk.y1 then
            local d = lakeEdge(lk, wx + 1, wy + 1.5)
            if d < -3 then return water end
            if d < 5 then
              return shorePattern(
                subColour(lk, wx + 0.5, wy + 0.5), subColour(lk, wx + 1.5, wy + 0.5),
                subColour(lk, wx + 0.5, wy + 1.5), subColour(lk, wx + 1.5, wy + 1.5),
                subColour(lk, wx + 0.5, wy + 2.5), subColour(lk, wx + 1.5, wy + 2.5))
            end
          end
        end
        return plain
      end)
    end

    for gy = floor(camY / DECO_GRID) - 1, floor((camY + scr.PH) / DECO_GRID) do
      for gx = floor(camX / DECO_GRID) - 1, floor((camX + scr.PW) / DECO_GRID) do
        local d = decoAt(gx, gy)
        if d then scr.sprite(d[1], d[2] - camX, d[3] - camY) end
      end
    end
    self.viewLakes, self.nViewLakes = viewLakes, nv
  end

  -- lily pads, reeds and moving sparkles (call after drawGround)
  function self.drawLakeDecor(scr, camX, camY, frame)
    for i = 1, self.nViewLakes or 0 do
      local lk = self.viewLakes[i]
      for _, l in ipairs(lk.lilies) do scr.sprite(spr.lily, l[1] - 2 - camX, l[2] - 2 - camY) end
      for _, r in ipairs(lk.reeds) do scr.sprite(spr.reed, r[1] - 2 - camX, r[2] - 4 - camY) end
      -- sparkles drift slowly and change every second
      local t = floor(frame / 20)
      for k = 1, 4 do
        local c = lk.circles[1 + (k % #lk.circles)]
        local a = hash(k, t, 7) * 6.283
        local d = hash(k, t, 8) * (c[3] - 8)
        scr.sprite(spr.sparkle, c[1] + math.cos(a) * d - camX + (frame % 20) * 0.2, c[2] + math.sin(a) * d - camY)
      end
    end
  end

  -- props --------------------------------------------------------------------
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
        if bx * bx + by * by > 70 * 70 and waterEdge(bx, by) > 12 and not self.nearOutpost(bx, by, 60) then
          pr = { spr = sp, x = x, y = y, bx = bx, by = by, br = br, z = y + sp.h }
        end
      end
      row[rx] = pr
    end
    return pr
  end

  function self.propsInView(camX, camY, PW, PH, add)
    for ry = floor((camY - 24) / RH), floor((camY + PH) / RH) do
      for rx = floor((camX - 24) / RW), floor((camX + PW) / RW) do
        local pr = propAt(rx, ry)
        if pr then add(pr.spr, pr.x, pr.y, false, nil, pr.z) end
      end
    end
  end

  -- outpost sites ------------------------------------------------------------
  -- returns { key, x, y } or false. (x, y) = centre of the camp (tent foot)
  local outCache = {}
  local function outpostAt(ox, oy)
    local key = ox * 65536 + oy
    local o = outCache[key]
    if o ~= nil then return o end
    o = false
    if hash(ox, oy, 21) < 0.55 then
      local x = ox * OW + 70 + floor(hash(ox, oy, 22) * (OW - 140))
      local y = oy * OH + 70 + floor(hash(ox, oy, 23) * (OH - 140))
      if x * x + y * y > 170 * 170 and waterEdge(x, y) > 50 then
        o = { key = key, x = x, y = y }
      end
    end
    outCache[key] = o
    return o
  end

  function self.nearOutpost(x, y, range)
    local ox, oy = floor(x / OW), floor(y / OH)
    for yy = oy - 1, oy + 1 do
      for xx = ox - 1, ox + 1 do
        local o = outpostAt(xx, yy)
        if o then
          local dx, dy = o.x - x, o.y - y
          if dx * dx + dy * dy < range * range then return o end
        end
      end
    end
    return nil
  end

  function self.outpostsNear(x, y, range, out)
    local n = 0
    local ox, oy = floor(x / OW), floor(y / OH)
    for yy = oy - 1, oy + 1 do
      for xx = ox - 1, ox + 1 do
        local o = outpostAt(xx, yy)
        if o then
          local dx, dy = o.x - x, o.y - y
          if dx * dx + dy * dy < range * range then n = n + 1; out[n] = o end
        end
      end
    end
    for i = n + 1, #out do out[i] = nil end
    return n
  end

  -- collision: push a circle (x, y, r) out of props and water ----------------
  local pushLakes = {}
  function self.pushOut(x, y, r)
    local rx0, ry0 = floor(x / RW), floor(y / RH)
    for ry = ry0 - 1, ry0 + 1 do
      for rx = rx0 - 1, rx0 + 1 do
        local pr = propAt(rx, ry)
        if pr then
          local dx, dy = x - pr.bx, y - pr.by
          local m = r + pr.br
          local d2 = dx * dx + dy * dy
          if d2 < m * m then
            local d = sqrt(d2)
            if d < 0.01 then dx, dy, d = 1, 0, 1 end
            x = pr.bx + dx / d * m
            y = pr.by + dy / d * m
          end
        end
      end
    end
    local n = lakesNear(x, y, pushLakes)
    for i = 1, n do
      local lk = pushLakes[i]
      if x > lk.x0 - r and x < lk.x1 + r and y > lk.y0 - r and y < lk.y1 + r then
        for _ = 1, 2 do
          for _, c in ipairs(lk.circles) do
            local dx, dy = x - c[1], y - c[2]
            local m = c[3] + r
            local d2 = dx * dx + dy * dy
            if d2 < m * m then
              local d = sqrt(d2)
              if d < 0.01 then dx, dy, d = 1, 0, 1 end
              x = c[1] + dx / d * m
              y = c[2] + dy / d * m
            end
          end
        end
      end
    end
    return x, y
  end

  return self
end

return W
