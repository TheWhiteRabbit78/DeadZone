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
local OW, OH = 640, 520           -- one outpost chance per region of this size
local BLK = 8                     -- biome lookup block size (pixels)
local MBW, MBH = 1500, 1500       -- one military base chance per region of this size
local BASE_HW, BASE_HH = 130, 95  -- half size of a base compound
local WALL = 6                    -- wall thickness
local GATE = 22                   -- half width of a gate
local CMW, CMH = 2000, 2000       -- one cemetery chance per region of this size
local CEM_HW, CEM_HH = 118, 88

-- Biomes come from two smooth noise maps, temperature and humidity (like
-- Minecraft). Temperature changes gradually, so cold and hot biomes always
-- have a mild band between them - snow never touches desert.
--   cold: tundra / snowforest / frozenbog
--   mild: plains / forest / swamp
--   hot:  desert / badlands / jungle
W.BIOMES = {
  plains     = { name = "PLAINS",        ground = "G", props = 0.22, set = { "oak", 0.4, "pine", 0.75, "rock", 1 },
                 deco = 0.30, decos = { "tuft1", "tuft2", "tuft3", "d_flowerY", "d_flowerR" } },
  forest     = { name = "FOREST",        ground = "G", props = 0.5,  set = { "oak", 0.45, "pine", 0.95, "rock", 1 },
                 deco = 0.40, decos = { "tuft1", "d_shade", "d_fern", "d_shroom", "tuft2" } },
  swamp      = { name = "SWAMP",         ground = "L", props = 0.2,  set = { "deadtree", 0.45, "mossrock", 0.75, "tomb", 1 },
                 deco = 0.45, decos = { "d_moss", "d_mud", "d_reed", "d_puddle", "d_puddle" } },
  desert     = { name = "DESERT",        ground = "S", props = 0.13, set = { "cactus", 0.4, "cactus2", 0.7, "deadtree", 0.85, "redrock", 1 },
                 deco = 0.22, decos = { "d_sand1", "d_sand2", "d_sand1", "d_bones", "tumble" } },
  badlands   = { name = "BADLANDS",      ground = "N", props = 0.18, set = { "redrock", 0.6, "deadtree", 1 },
                 deco = 0.30, decos = { "d_crack2", "d_stripe", "d_crack2", "d_bones", "d_stripe" } },
  jungle     = { name = "JUNGLE",        ground = "G", props = 0.42, set = { "palm", 0.45, "palm2", 0.9, "mossrock", 1 },
                 deco = 0.55, decos = { "d_leaf", "d_fern", "d_shade", "d_flowerR", "d_flowerY" } },
  tundra     = { name = "SNOW TUNDRA",   ground = "W", props = 0.1,  set = { "snowrock", 0.6, "snowpine", 1 },
                 deco = 0.22, decos = { "d_snow1", "d_snow2", "d_ice", "d_snow1", "d_ice" } },
  snowforest = { name = "SNOWY FOREST",  ground = "W", props = 0.45, set = { "snowpine", 0.6, "snowoak", 0.95, "snowrock", 1 },
                 deco = 0.25, decos = { "d_snow1", "d_snow2", "d_snow2", "d_ice", "d_snow1" } },
  frozenbog  = { name = "FROZEN BOG",    ground = "A", props = 0.14, set = { "snowrock", 0.5, "snowoak", 1 },
                 deco = 0.45, decos = { "d_slush1", "d_slush2", "d_crack", "d_slush1", "d_ice" } },
}
W.BIOME_GRID = {
  { "tundra", "snowforest", "frozenbog" },
  { "plains", "forest", "swamp" },
  { "desert", "badlands", "jungle" },
}
W.COLD = { tundra = true, snowforest = true, frozenbog = true }

function W.new(spr, seed)
  local self = {}
  local s = P.slot
  local plain = G.pattern({ s.G, s.G, s.G, s.G, s.G, s.G })
  local water = G.pattern({ s.U, s.U, s.U, s.U, s.U, s.U })
  self.plain = plain

  local DECO = {
    tuft1 = G.compile({ "g.g", ".g." }),
    tuft2 = G.compile({ "g..", ".g.", ".g." }),
    tuft3 = G.compile({ ".g", "g.", "g." }),
  }
  local function decoSpr(name) return DECO[name] or spr[name] end

  local function hash(x, y, k)
    local n = sin(x * 127.1 + y * 311.7 + (seed + k) * 74.7) * 43758.5453
    return n - floor(n)
  end

  -- biomes -----------------------------------------------------------------
  local function vnoise(x, y, k)
    local x0, y0 = floor(x), floor(y)
    local fx, fy = x - x0, y - y0
    fx, fy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
    local a, b = hash(x0, y0, k), hash(x0 + 1, y0, k)
    local c, d = hash(x0, y0 + 1, k), hash(x0 + 1, y0 + 1, k)
    local top = a + (b - a) * fx
    return top + (c + (d - c) * fx - top) * fy
  end
  local function climate(x, y)
    local t = 0.78 * vnoise(x / 2200, y / 2200, 101) + 0.22 * vnoise(x / 800, y / 800, 102)
    local h = 0.78 * vnoise(x / 1900, y / 1900, 201) + 0.22 * vnoise(x / 700, y / 700, 202)
    t, h = (t - 0.5) * 1.7 + 0.5, (h - 0.5) * 1.6 + 0.5
    -- the start area is always calm plains
    local d = sqrt(x * x + y * y)
    if d < 1400 then
      local w = min(1, (1400 - d) / 700)
      t, h = t + (0.5 - t) * w, h + (0.3 - h) * w
    end
    return t, h
  end
  self.climate = climate
  local function classify(t, h)
    local col = (t < 0.235) and 1 or ((t > 0.755) and 3 or 2)
    local row = (h < 0.46) and 1 or ((h > 0.73) and 3 or 2)
    return W.BIOME_GRID[col][row]
  end
  local blkCache, blkRows = {}, 0
  local function biomeBlock(bx, by)
    local row = blkCache[by]
    if not row then
      if blkRows > 4000 then blkCache, blkRows = {}, 0 end
      row = {}
      blkCache[by] = row
      blkRows = blkRows + 1
    end
    local b = row[bx]
    if not b then
      b = classify(climate(bx * BLK + 4, by * BLK + 4))
      row[bx] = b
    end
    return b
  end
  function self.biomeAt(x, y) return biomeBlock(floor(x / BLK), floor(y / BLK)) end
  local biomeAt = self.biomeAt
  -- stable per-pixel jitter so borders are ragged instead of blocky
  local JIT = {}
  for i = 0, 255 do JIT[i] = floor(hash(i, 7, 909) * 11) - 5 end
  local function biomeJit(x, y)
    local j = JIT[(x % 16) * 16 + (y % 16)]
    local k = JIT[(y % 16) * 16 + ((x + 5) % 16)]
    return biomeBlock(floor((x + j) / BLK), floor((y + k) / BLK))
  end
  -- solid ground pattern per biome
  local groundPat, groundCol = {}, {}
  for id, b in pairs(W.BIOMES) do
    local c = s[b.ground]
    groundCol[id] = c
    groundPat[id] = G.pattern({ c, c, c, c, c, c })
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
        lk.biome = biomeAt(cx, cy)
        lk.frozen = W.COLD[lk.biome] or false
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
      local x, y = gx * DECO_GRID + floor(hash(gx, gy, 1) * 6), gy * DECO_GRID + floor(hash(gx, gy, 2) * 6)
      local bd = W.BIOMES[biomeAt(x, y)]
      if r < bd.deco then
        local list = bd.decos
        local name = list[1 + floor(hash(gx, gy, 3) * #list)]
        -- the last two entries are the rare ones
        if r > bd.deco * 0.025 and (name == list[4] or name == list[5]) then name = list[1 + floor(hash(gx, gy, 4) * 3)] end
        if waterEdge(x, y) > 4 and not self.nearBase(x, y, 4) then d = { decoSpr(name), x, y } end
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
  local SHORE = { desert = s.g, badlands = s.g, tundra = s.A, snowforest = s.A, frozenbog = s.W, swamp = s.B, jungle = s.S }
  local function subColour(lk, x, y)
    local d = lakeEdge(lk, x, y)
    if d < 0 then return lk.frozen and s.C or s.U
    elseif d < 2.5 then return SHORE[lk.biome] or s.S
    else return groundCol[biomeAt(x, y)] end
  end
  local ice = G.pattern({ s.C, s.C, s.C, s.C, s.C, s.C })

  local basePattern
  local viewLakes = {}
  local bgrid, ugrid, colIdx, rowIdx = {}, {}, {}, {}
  local viewBases, nvb = {}, 0
  -- concrete floor with tile seams, walls dark with a light top edge
  -- each base is rasterised once into a colour table (walls, floor, seams)
  local function rasteriseCem(b)
    local r, bw = {}, b.x1 - b.x0
    for yy = 0, b.y1 - b.y0 - 1 do
      for xx = 0, bw - 1 do
        local x, y = b.x0 + xx, b.y0 + yy
        local hv = (x * 31 + y * 17) % 23
        local c = (hv == 0) and s.D or ((hv == 7) and s.N or s.B)
        for _, w in ipairs(b.walls) do
          if not w.crypt and x >= w[1] and x < w[3] and y >= w[2] and y < w[4] then
            -- iron fence: posts every 5 px, rails between
            local post = (w[3] - w[1] > w[4] - w[2]) and ((x - w[1]) % 5 == 0) or ((y - w[2]) % 5 == 0)
            c = post and s.K or (((y - w[2]) == 1 or (x - w[1]) == 1) and s.A or s.K)
            break
          end
        end
        r[yy * bw + xx] = c
      end
    end
    b.raster, b.bw = r, bw
  end
  local function rasterise(b)
    if b.kind == "cemetery" then return rasteriseCem(b) end
    local r, bw = {}, b.x1 - b.x0
    for yy = 0, b.y1 - b.y0 - 1 do
      for xx = 0, bw - 1 do
        local x, y = b.x0 + xx, b.y0 + yy
        local c = ((xx % 24 == 0) or (yy % 24 == 0)) and s.D or s.A
        for _, w in ipairs(b.walls) do
          if x >= w[1] and x < w[3] and y >= w[2] and y < w[4] then
            c = (y == w[2] or y == w[2] + 1) and s.A or (((x + y) % 7 == 0) and s.K or s.D)
            break
          end
        end
        r[yy * bw + xx] = c
      end
    end
    b.raster, b.bw = r, bw
  end
  local function basePix(b, x, y)
    if x < b.x0 or x >= b.x1 or y < b.y0 or y >= b.y1 then return groundCol[biomeAt(x, y)] end
    return b.raster[(y - b.y0) * b.bw + (x - b.x0)]
  end
  function basePattern(b, wx, wy)
    if not b.raster then rasterise(b); b.pcache = {} end
    local k = (wy - b.y0 + 4) * 1024 + (wx - b.x0 + 4)
    local pt = b.pcache[k]
    if pt then return pt end
    pt = shorePattern(basePix(b, wx, wy), basePix(b, wx + 1, wy), basePix(b, wx, wy + 1),
      basePix(b, wx + 1, wy + 1), basePix(b, wx, wy + 2), basePix(b, wx + 1, wy + 2))
    b.pcache[k] = pt
    return pt
  end
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

    -- ground: one solid pattern per biome. A block whose 8 neighbours are the
    -- same biome is drawn solid; cells near a border are worked out per pixel
    -- (with a little jitter so the edge looks natural)
    local bx0, by0 = floor(camX / BLK) - 2, floor(camY / BLK) - 2
    local nbx, nby = floor(scr.PW / BLK) + 6, floor(scr.PH / BLK) + 6
    for iy = 0, nby - 1 do
      for ix = 0, nbx - 1 do bgrid[iy * nbx + ix] = biomeBlock(bx0 + ix, by0 + iy) end
    end
    for iy = 1, nby - 2 do
      for ix = 1, nbx - 2 do
        local i = iy * nbx + ix
        local a = bgrid[i]
        if bgrid[i - 1] == a and bgrid[i + 1] == a and bgrid[i - nbx] == a and bgrid[i + nbx] == a
          and bgrid[i - nbx - 1] == a and bgrid[i - nbx + 1] == a and bgrid[i + nbx - 1] == a and bgrid[i + nbx + 1] == a then
          ugrid[i] = groundPat[a]
        else
          ugrid[i] = false
        end
      end
    end
    -- bases actually overlapping the screen
    local nb = self.basesNear(camX + scr.PW / 2, camY + scr.PH / 2, scr.PW, viewBases)
    nvb = 0
    for i = 1, nb do
      local b = viewBases[i]
      if b.x1 > camX and b.x0 < camX + scr.PW and b.y1 > camY and b.y0 < camY + scr.PH then
        nvb = nvb + 1; viewBases[nvb] = b
      end
    end
    -- whole view inside one biome: every cell is the same pattern
    local only = ugrid[2 * nbx + 2]
    if only then
      for iy = 2, nby - 3 do
        for ix = 2, nbx - 3 do
          if ugrid[iy * nbx + ix] ~= only then only = nil; break end
        end
        if not only then break end
      end
    end
    if nvb > 0 then only = nil end
    for cx = 0, scr.CW - 1 do colIdx[cx] = floor((camX + cx * 2 + 1) / BLK) - bx0 end
    for cy = 0, scr.CH - 1 do rowIdx[cy] = (floor((camY + cy * 3 + 1) / BLK) - by0) * nbx end
    local function land(wx, wy, cx, cy)
      for i = 1, nvb do
        local b = viewBases[i]
        if wx + 2 > b.x0 and wx < b.x1 and wy + 3 > b.y0 and wy < b.y1 then return basePattern(b, wx, wy) end
      end
      local u = only or ugrid[rowIdx[cy] + colIdx[cx]]
      if u then return u end
      -- border: one jittered lookup per cell (ragged edge at cell size, cheap)
      return groundPat[biomeJit(wx + 1, wy + 1)]
    end
    if nv == 0 and only then
      scr.fillBase(function() return only end)
    elseif nv == 0 then
      scr.fillBase(function(cx, cy) return land(camX + cx * 2, camY + cy * 3, cx, cy) end)
    else
      scr.fillBase(function(cx, cy)
        local wx, wy = camX + cx * 2, camY + cy * 3
        for i = 1, nv do
          local lk = viewLakes[i]
          if wx + 2 > lk.x0 and wx < lk.x1 and wy + 3 > lk.y0 and wy < lk.y1 then
            local d = lakeEdge(lk, wx + 1, wy + 1.5)
            if d < -3 then return lk.frozen and ice or water end
            if d < 5 then
              return shorePattern(
                subColour(lk, wx + 0.5, wy + 0.5), subColour(lk, wx + 1.5, wy + 0.5),
                subColour(lk, wx + 0.5, wy + 1.5), subColour(lk, wx + 1.5, wy + 1.5),
                subColour(lk, wx + 0.5, wy + 2.5), subColour(lk, wx + 1.5, wy + 2.5))
            end
          end
        end
        return land(wx, wy, cx, cy)
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
      if not lk.frozen then
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
      local bd = W.BIOMES[biomeAt(rx * RW + RW / 2, ry * RH + RH / 2)]
      if r < bd.props then
        local q = r / bd.props
        local set = bd.set
        local kind = set[#set - 1]
        for i = 1, #set, 2 do if q < set[i + 1] then kind = set[i]; break end end
        local sp = spr[kind]
        local x = rx * RW + floor(hash(rx, ry, 12) * (RW - sp.w))
        local y = ry * RH + floor(hash(rx, ry, 13) * (RH - sp.h))
        local bx, by, br
        if kind:find("rock") then
          bx, by, br = x + sp.w / 2, y + sp.h - 3, 5
        elseif kind == "tumble" or kind == "tomb" then
          bx, by, br = x + sp.w / 2, y + sp.h - 2, 3
        else
          bx, by, br = x + sp.w / 2, y + sp.h - 2, (kind == "oak" or kind == "snowoak") and 3 or 2
        end
        if bx * bx + by * by > 70 * 70 and waterEdge(bx, by) > 12 and not self.nearOutpost(bx, by, 60) and not self.nearBase(bx, by, 30) then
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
  local function rawSite(ox, oy)
    if hash(ox, oy, 21) >= 0.45 then return nil end
    local x = ox * OW + 90 + floor(hash(ox, oy, 22) * (OW - 180))
    local y = oy * OH + 90 + floor(hash(ox, oy, 23) * (OH - 180))
    if x * x + y * y <= 300 * 300 or waterEdge(x, y) <= 50 or self.nearBase(x, y, 200) then return nil end
    return x, y
  end
  local MIN_GAP = 450   -- camps never closer than this to each other
  local function outpostAt(ox, oy)
    local key = ox * 65536 + oy
    local o = outCache[key]
    if o ~= nil then return o end
    o = false
    local x, y = rawSite(ox, oy)
    if x then
      local ok = true
      -- the neighbour with the smaller key wins when two camps are too close
      for yy = oy - 1, oy + 1 do
        for xx = ox - 1, ox + 1 do
          if (xx ~= ox or yy ~= oy) and xx * 65536 + yy < key then
            local nx, ny = rawSite(xx, yy)
            if nx and (nx - x) ^ 2 + (ny - y) ^ 2 < MIN_GAP * MIN_GAP then ok = false end
          end
        end
      end
      if ok then o = { key = key, x = x, y = y } end
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

  -- military bases ------------------------------------------------------------
  -- rare walled compounds: walls with gates W, E and S, concrete inside.
  -- layout positions are relative to the centre.
  W.BASE_LAYOUT = {
    mg = { { -BASE_HW + 24, -BASE_HH + 22 }, { BASE_HW - 24, -BASE_HH + 22 } },
    soldiers = { { -70, -30 }, { -30, -55 }, { 30, -55 }, { 70, -30 }, { -80, 40 }, { -35, 55 }, { 35, 55 }, { 80, 40 } },
    crates = { { -100, 0 }, { 96, 4 }, { -10, -70 }, { 14, 70 }, { -56, 10 }, { 60, -4 } },
  }
  local baseCache = {}
  local function baseAt(bx, by)
    local key = bx * 65536 + by
    local b = baseCache[key]
    if b ~= nil then return b end
    b = false
    if hash(bx, by, 501) < 0.55 then
      local x = bx * MBW + 320 + floor(hash(bx, by, 502) * (MBW - 640))
      local y = by * MBH + 320 + floor(hash(bx, by, 503) * (MBH - 640))
      if x * x + y * y > 1800 * 1800 and waterEdge(x, y) > 220 then
        local x0, y0, x1, y1 = x - BASE_HW, y - BASE_HH, x + BASE_HW, y + BASE_HH
        b = { kind = "base", key = key, x = x, y = y, x0 = x0, y0 = y0, x1 = x1, y1 = y1, walls = {
          { x0, y0, x1, y0 + WALL },                                        -- north
          { x0, y1 - WALL, x - GATE, y1 }, { x + GATE, y1 - WALL, x1, y1 },   -- south + gate
          { x0, y0, x0 + WALL, y - GATE }, { x0, y + GATE, x0 + WALL, y1 },   -- west + gate
          { x1 - WALL, y0, x1, y - GATE }, { x1 - WALL, y + GATE, x1, y1 },   -- east + gate
        } }
      end
    end
    baseCache[key] = b
    return b
  end
  -- cemeteries: small iron-fenced graveyards with a crypt, gaps N and S
  W.CEM_LAYOUT = {
    archers = { { -80, -50 }, { 80, -50 }, { -90, 40 }, { 90, 40 }, { -30, -66 }, { 30, -66 } },
    pikes = { { -50, -20 }, { 50, -20 }, { -50, 30 }, { 50, 30 }, { 0, 48 } },
    shields = { { -20, -40 }, { 20, -40 }, { -70, 0 }, { 70, 0 }, { -20, 30 }, { 20, 30 } },
  }
  local cemCache = {}
  local function cemAt(cx, cy)
    local key = cx * 65536 + cy + 7e9
    local c = cemCache[key]
    if c ~= nil then return c end
    c = false
    if hash(cx, cy, 601) < 0.6 then
      local x = cx * CMW + 300 + floor(hash(cx, cy, 602) * (CMW - 600))
      local y = cy * CMH + 300 + floor(hash(cx, cy, 603) * (CMH - 600))
      if x * x + y * y > 2500 * 2500 and waterEdge(x, y) > 200 then
        -- keep away from military bases
        local ok = true
        local bx, by = floor(x / MBW), floor(y / MBH)
        for yy = by - 1, by + 1 do for xx = bx - 1, bx + 1 do
          local b = baseAt(xx, yy)
          if b and (b.x - x) ^ 2 + (b.y - y) ^ 2 < 600 * 600 then ok = false end
        end end
        if ok then
          local x0, y0, x1, y1 = x - CEM_HW, y - CEM_HH, x + CEM_HW, y + CEM_HH
          local G2 = 16
          c = { kind = "cemetery", key = key, x = x, y = y, x0 = x0, y0 = y0, x1 = x1, y1 = y1, walls = {
            { x0, y0, x - G2, y0 + 3 }, { x + G2, y0, x1, y0 + 3 },     -- north fence + gap
            { x0, y1 - 3, x - G2, y1 }, { x + G2, y1 - 3, x1, y1 },     -- south fence + gap
            { x0, y0, x0 + 3, y1 }, { x1 - 3, y0, x1, y1 },             -- west, east
            { x - 10, y - 7, x + 10, y + 1, crypt = true },             -- the crypt
          }, graves = {} }
          for gy = -60, 64, 22 do
            for gx = -100, 100, 18 do
              if math.abs(gx) > 26 or math.abs(gy) > 26 then
                if hash(gx + x, gy + y, 610) < 0.55 then c.graves[#c.graves + 1] = { x + gx, y + gy, hash(gx, gy, 611) < 0.5 } end
              end
            end
          end
        end
      end
    end
    cemCache[key] = c
    return c
  end

  function self.basesNear(x, y, range, out)
    local n = 0
    local bx, by = floor(x / MBW), floor(y / MBH)
    for yy = by - 1, by + 1 do
      for xx = bx - 1, bx + 1 do
        local b = baseAt(xx, yy)
        if b and x > b.x0 - range and x < b.x1 + range and y > b.y0 - range and y < b.y1 + range then
          n = n + 1; out[n] = b
        end
      end
    end
    bx, by = floor(x / CMW), floor(y / CMH)
    for yy = by - 1, by + 1 do
      for xx = bx - 1, bx + 1 do
        local b = cemAt(xx, yy)
        if b and x > b.x0 - range and x < b.x1 + range and y > b.y0 - range and y < b.y1 + range then
          n = n + 1; out[n] = b
        end
      end
    end
    for i = n + 1, #out do out[i] = nil end
    return n
  end
  local tmpBases = {}
  function self.nearBase(x, y, range)
    if self.basesNear(x, y, range, tmpBases) > 0 then return tmpBases[1] end
    return nil
  end
  -- base whose walls enclose (x, y)
  function self.inBase(x, y)
    local b = self.nearBase(x, y, 0)
    if b and b.kind == "base" and x > b.x0 + WALL and x < b.x1 - WALL and y > b.y0 + WALL and y < b.y1 - WALL then return b end
    return nil
  end
  local hitBases = {}
  -- list/n: optional bases already looked up nearby (saves time for bullets)
  function self.wallHit(x, y, list, n)
    if not list then list = hitBases; n = self.basesNear(x, y, 2, hitBases) end
    for i = 1, n do
      local b = list[i]
      if b.kind == "base" and x >= b.x0 and x < b.x1 and y >= b.y0 and y < b.y1 then
      for _, w in ipairs(b.walls) do
        if x >= w[1] and x < w[3] and y >= w[2] and y < w[4] then return true end
      end
      end
    end
    return false
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
    local nb = self.basesNear(x, y, r + 2, hitBases)
    for i = 1, nb do
      for _, w in ipairs(hitBases[i].walls) do
        -- circle vs rectangle
        local cx, cy = max(w[1], min(x, w[3])), max(w[2], min(y, w[4]))
        local dx, dy = x - cx, y - cy
        local d2 = dx * dx + dy * dy
        if d2 < r * r then
          if d2 < 0.0001 then
            -- centre inside the wall: push out the short way
            local l, rr, t, bb = x - w[1], w[3] - x, y - w[2], w[4] - y
            local m = min(l, rr, t, bb)
            if m == l then x = w[1] - r elseif m == rr then x = w[3] + r elseif m == t then y = w[2] - r else y = w[4] + r end
          else
            local d = sqrt(d2)
            x, y = cx + dx / d * r, cy + dy / d * r
          end
        end
      end
    end
    local n = lakesNear(x, y, pushLakes)
    for i = 1, n do
      local lk = pushLakes[i]
      if not lk.frozen and x > lk.x0 - r and x < lk.x1 + r and y > lk.y0 - r and y < lk.y1 + r then
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
