-- DEAD ZONE gfx: pixel renderer for CC:Tweaked monitors.
--
-- Every text cell is drawn with a "teletext" character (128-159) that splits
-- the cell into 2x3 square sub-pixels. A cell can only show 2 colours, so
-- when sprites overlap the ground and give a cell 3+ colours, the closest
-- 2 are kept.
--
-- Layers per frame:
--   1. base   : pre-encoded ground patterns, one per cell (cheap)
--   2. sprites: drawn pixel-by-pixel, only into the cells they touch
--   3. text   : normal characters (HUD) on top
-- Only rows that changed since the last frame are sent to the monitor.

local P = require("dz.palette")

local floor = math.floor
local concat = table.concat

local G = {}

local HEX = {}
for i = 0, 15 do HEX[i] = ("0123456789abcdef"):sub(i + 1, i + 1) end
G.HEX = HEX

local TCH = {}
for b = 0, 31 do TCH[b] = string.char(128 + b) end
TCH[0] = " "

local DIST = P.dist

-- reused scratch tables for encode()
local cnt = {}
for i = 0, 15 do cnt[i] = 0 end
local m = {}

-- 6 pixel colours (TL,TR,ML,MR,BL,BR) -> char, fgHex, bgHex
local function encode(c)
  local bg = c[6]
  local fg = nil
  local many = false
  for i = 1, 5 do
    local v = c[i]
    if v ~= bg then
      if fg == nil then fg = v
      elseif v ~= fg then many = true; break end
    end
  end

  if not many then
    if fg == nil then return " ", HEX[bg], HEX[bg] end
    local bits = 0
    if c[1] == fg then bits = bits + 1 end
    if c[2] == fg then bits = bits + 2 end
    if c[3] == fg then bits = bits + 4 end
    if c[4] == fg then bits = bits + 8 end
    if c[5] == fg then bits = bits + 16 end
    return TCH[bits], HEX[fg], HEX[bg]
  end

  -- 3+ colours: keep the most common one + the second that loses least detail
  local best1, bestN = c[1], 0
  for i = 1, 6 do
    local v = c[i]
    local n = cnt[v] + 1
    cnt[v] = n
    if n > bestN then best1, bestN = v, n end
  end
  local best2, bestErr = nil, nil
  for i = 1, 6 do
    local cand = c[i]
    if cand ~= best1 and cnt[cand] > 0 then
      local err = 0
      local d1, d2 = DIST[best1], DIST[cand]
      for j = 1, 6 do
        local v = c[j]
        local e1, e2 = d1[v], d2[v]
        err = err + (e1 < e2 and e1 or e2)
      end
      if bestErr == nil or err < bestErr then best2, bestErr = cand, err end
      cnt[cand] = -cnt[cand]  -- mark tested (restored below)
    end
  end
  for i = 1, 6 do cnt[c[i]] = 0 end

  local d1, d2 = DIST[best1], DIST[best2]
  for i = 1, 6 do
    local v = c[i]
    if v == best1 or v == best2 then m[i] = v
    else m[i] = (d1[v] <= d2[v]) and best1 or best2 end
  end
  bg = m[6]
  fg = (bg == best1) and best2 or best1
  local bits = 0
  if m[1] == fg then bits = bits + 1 end
  if m[2] == fg then bits = bits + 2 end
  if m[3] == fg then bits = bits + 4 end
  if m[4] == fg then bits = bits + 8 end
  if m[5] == fg then bits = bits + 16 end
  return TCH[bits], HEX[fg], HEX[bg]
end
G.encode = encode

-- a ground pattern: 6 slots -> pre-encoded cell
function G.pattern(p6)
  local ch, fg, bg = encode(p6)
  return { px = p6, ch = ch, fg = fg, bg = bg }
end

-- turn rows of letters into a pixel list (normal + mirrored)
function G.compile(rows)
  local h, w = #rows, #rows[1]
  local px, pxf = {}, {}
  for y = 1, h do
    local r = rows[y]
    for x = 1, w do
      local ch = r:sub(x, x)
      if ch ~= "." then
        local s = P.slot[ch]
        if not s then error("unknown sprite colour '" .. ch .. "'") end
        px[#px + 1] = x - 1; px[#px + 1] = y - 1; px[#px + 1] = s
        pxf[#pxf + 1] = w - x; pxf[#pxf + 1] = y - 1; pxf[#pxf + 1] = s
      end
    end
  end
  return { w = w, h = h, px = px, pxf = pxf }
end

function G.new(t)
  local self = {}
  local CW, CH = t.getSize()
  local PW, PH = CW * 2, CH * 3
  self.CW, self.CH, self.PW, self.PH = CW, CH, PW, PH

  local rc, rf, rb = {}, {}, {}
  local lastC, lastF, lastB = {}, {}, {}
  for y = 1, CH do rc[y], rf[y], rb[y] = {}, {}, {} end

  local base = {}       -- idx -> pattern
  local cellPix = {}    -- idx -> {6 slots} for cells touched by sprites
  local dirty, nDirty = {}, 0
  local pool, nPool = {}, 0
  local texts, nTexts = {}, 0

  self.stats = { dirty = 0, rows = 0 }

  -- 1. base layer: fn(cx, cy) -> pattern  (cx, cy are 0-based screen cells)
  function self.fillBase(fn)
    local idx = 0
    for cy = 0, CH - 1 do
      local c, f, b = rc[cy + 1], rf[cy + 1], rb[cy + 1]
      for cx = 0, CW - 1 do
        idx = idx + 1
        local p = fn(cx, cy)
        base[idx] = p
        c[cx + 1], f[cx + 1], b[cx + 1] = p.ch, p.fg, p.bg
      end
    end
  end

  local function touch(idx)
    local c = cellPix[idx]
    if c then return c end
    if nPool > 0 then c = pool[nPool]; pool[nPool] = nil; nPool = nPool - 1 else c = {} end
    local bp = base[idx].px
    c[1], c[2], c[3], c[4], c[5], c[6] = bp[1], bp[2], bp[3], bp[4], bp[5], bp[6]
    cellPix[idx] = c
    nDirty = nDirty + 1
    dirty[nDirty] = idx
    return c
  end

  -- 2. sprites / pixels (x, y in screen pixels, 0-based)
  function self.sprite(spr, x, y, flip, tint)
    x, y = floor(x), floor(y)
    if x >= PW or y >= PH or x + spr.w <= 0 or y + spr.h <= 0 then return end
    local px = flip and spr.pxf or spr.px
    for i = 1, #px, 3 do
      local sx, sy = x + px[i], y + px[i + 1]
      if sx >= 0 and sx < PW and sy >= 0 and sy < PH then
        local cx, cy = floor(sx / 2), floor(sy / 3)
        local c = touch(cy * CW + cx + 1)
        c[(sy - cy * 3) * 2 + (sx - cx * 2) + 1] = tint or px[i + 2]
      end
    end
  end

  function self.pixel(x, y, col)
    x, y = floor(x), floor(y)
    if x < 0 or y < 0 or x >= PW or y >= PH then return end
    local cx, cy = floor(x / 2), floor(y / 3)
    local c = touch(cy * CW + cx + 1)
    c[(y - cy * 3) * 2 + (x - cx * 2) + 1] = col
  end

  function self.rect(x, y, w, h, col)
    for yy = y, y + h - 1 do
      for xx = x, x + w - 1 do self.pixel(xx, yy, col) end
    end
  end

  -- 3. text (cx, cy are 1-based text cells; fg/bg are slot numbers)
  function self.text(cx, cy, s, fg, bg)
    nTexts = nTexts + 1
    local e = texts[nTexts]
    if not e then e = {}; texts[nTexts] = e end
    e[1], e[2], e[3], e[4], e[5] = cx, cy, s, fg, bg
  end

  function self.present()
    -- encode sprite cells
    for k = 1, nDirty do
      local idx = dirty[k]
      local c = cellPix[idx]
      local ch, fg, bg = encode(c)
      local cy = floor((idx - 1) / CW)
      local cx = idx - cy * CW
      cy = cy + 1
      rc[cy][cx], rf[cy][cx], rb[cy][cx] = ch, fg, bg
      cellPix[idx] = nil
      nPool = nPool + 1
      pool[nPool] = c
      dirty[k] = nil
    end
    self.stats.dirty = nDirty
    nDirty = 0

    -- text
    for k = 1, nTexts do
      local e = texts[k]
      local cx, cy, s, fg, bg = e[1], e[2], e[3], HEX[e[4]], HEX[e[5]]
      if cy >= 1 and cy <= CH then
        local c, f, b = rc[cy], rf[cy], rb[cy]
        for i = 1, #s do
          local x = cx + i - 1
          if x >= 1 and x <= CW then c[x], f[x], b[x] = s:sub(i, i), fg, bg end
        end
      end
    end
    nTexts = 0

    -- send changed rows
    local sent = 0
    for y = 1, CH do
      local sc, sf, sb = concat(rc[y]), concat(rf[y]), concat(rb[y])
      if sc ~= lastC[y] or sf ~= lastF[y] or sb ~= lastB[y] then
        t.setCursorPos(1, y)
        t.blit(sc, sf, sb)
        lastC[y], lastF[y], lastB[y] = sc, sf, sb
        sent = sent + 1
      end
    end
    self.stats.rows = sent
  end

  return self
end

return G
