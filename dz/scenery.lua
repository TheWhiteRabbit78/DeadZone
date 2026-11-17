-- DEAD ZONE menu art: night city background with parallax, embers, blood
-- moon, pixel panels, card icons and the title logo. Uses the night palette
-- (P.use("night")) - slot meanings are in P.N.

local floor, abs, max, min, sin = math.floor, math.abs, math.max, math.min, math.sin

local Sc = {}

----------------------------------------------------------------------- icons
-- 8x9 one-colour icons ('#' = pixel)
Sc.ICON = {
  gun = { "........", ".#######", "########", "####.#..", "###.....", "###.....", "###.....", "........", "........" },
  sword = { "......##", ".....###", "....###.", "#..###..", ".####...", "..##....", ".####...", "##..#...", "#......." },
  cross = { "...##...", ".######.", ".#.##.#.", "##....##", "###..###", "##....##", ".#.##.#.", ".######.", "...##..." },
  bullets = { ".#...#..", "###.###.", "###.###.", "###.###.", "###.###.", "###.###.", "###.###.", "###.###.", "........" },
  arrow = { "........", ".....#..", ".....##.", "########", "########", ".....##.", ".....#..", "........", "........" },
  flame = { "...#....", "...##...", "..###.#.", ".#####..", ".######.", "########", "###..###", ".##..##.", "..####.." },
  snow = { "...##...", "#..##..#", ".#.##.#.", "..####..", "########", "..####..", ".#.##.#.", "#..##..#", "...##..." },
  bolt = { "....###.", "...###..", "..###...", ".######.", "...###..", "..###...", ".###....", ".##.....", ".#......" },
  star = { "...##...", "...##...", "########", ".######.", "..####..", "..####..", ".##..##.", ".#....#.", "........" },
  bomb = { "......#.", ".....#.#", "....##..", "..####..", ".######.", ".######.", ".######.", "..####..", "........" },
  burst = { "#..##..#", ".#.##.#.", "..#..#..", "###..###", "###..###", "..#..#..", ".#.##.#.", "#..##..#", "........" },
  hourglass = { "########", ".######.", "..####..", "...##...", "...##...", "..#..#..", ".#....#.", "########", "........" },
  heart = { "........", ".##..##.", "########", "########", "########", ".######.", "..####..", "...##...", "........" },
  shield = { "########", "###.####", "###.####", "###.####", ".##.###.", ".##.###.", "..#.##..", "...##...", "........" },
  plus = { "...##...", "...##...", "...##...", "########", "########", "...##...", "...##...", "...##...", "........" },
  drop = { "...##...", "...##...", "..####..", "..####..", ".######.", ".######.", ".######.", "..####..", "........" },
  spikes = { "........", "#..#..#.", "#..#..#.", "##.##.##", "##.##.##", "########", "########", "........", "........" },
  boot = { "..###...", "..###...", "..###...", "..###...", "..####..", "..#####.", "..######", "..######", "........" },
  wind = { "........", "######..", "......#.", ".#####..", "........", "########", ".......#", "..######", "........" },
  book = { ".##..##.", "#..##..#", "#..##..#", "#..##..#", "#..##..#", "#..##..#", ".##..##.", "...##...", "........" },
  magnet = { ".##..##.", ".##..##.", ".##..##.", ".##..##.", ".##..##.", ".######.", "..####..", "........", "........" },
  gem = { "........", "..####..", ".##..##.", "########", ".######.", "..####..", "...##...", "........", "........" },
  clover = { ".##..##.", "####.###", ".######.", "..####..", ".######.", "###..###", ".##.###.", "...#....", "...#...." },
  dice = { "########", "#.####.#", "########", "###..###", "########", "#.####.#", "########", "........", "........" },
  banish = { "##....##", ".##..##.", "..####..", "...##...", "..####..", ".##..##.", "##....##", "........", "........" },
  chest = { "........", ".######.", "#......#", "########", "###..###", "########", "########", "........", "........" },
  card = { ".####...", ".#..####", ".#..#..#", ".#..#..#", ".####..#", "....#..#", "....####", "........", "........" },
  crown = { "#..##..#", "#..##..#", "##.##.##", "########", "########", "########", "........", "########", "........" },
  skull = { ".######.", "########", "#..##..#", "#..##..#", "########", ".##..##.", ".######.", ".#.##.#.", "........" },
  lock = { "..####..", ".##..##.", ".#....#.", ".#....#.", "########", "###..###", "###..###", "########", "........" },
}
-- compile to pixel offset lists
for k, rows in pairs(Sc.ICON) do
  local px = {}
  for y = 1, 9 do
    local r = rows[y]
    for x = 1, 8 do if r:sub(x, x) == "#" then px[#px + 1] = x - 1; px[#px + 1] = y - 1 end end
  end
  Sc.ICON[k] = px
end

local ICONOF = { gundmg_pct = "gun", rate_pct = "bullets", crit = "cross", critdmg = "cross", range_pct = "arrow",
  pierce = "arrow", dmg_pct = "sword", proj = "bullets", aoedmg_pct = "burst", area_pct = "burst", burn_pct = "flame",
  permafrost = "snow", cdr_pct = "hourglass", conductor = "bolt", meteordmg_pct = "star", boom_pct = "bomb",
  fireringdmg_pct = "flame", chain = "bolt", maxhp = "heart", armor = "shield", regen = "plus", dodge = "wind",
  maxhp_pct = "heart", lifesteal = "drop", thorns = "spikes", iframes_pct = "shield", retal = "spikes", revive = "heart",
  speed_pct = "boot", xp_pct = "book", magnet_pct = "magnet", souls_pct = "gem", luck = "clover", rerolls = "dice",
  banish = "banish", drops_pct = "chest", choices = "card", bosschests = "chest", headstart = "book" }
local STARTICON = { weapon = "gun", rare = "gem", firering = "flame", spell = "star", eshield = "shield" }

function Sc.iconFor(n)
  if n.id == "root" then return "skull" end
  if n.id:match("_apex$") then return "crown" end
  if n.start and STARTICON[n.start] then return STARTICON[n.start] end
  for k in pairs(n.mods) do if ICONOF[k] then return ICONOF[k] end end
  return "star"
end

----------------------------------------------------------------------- logo
local FONT = {
  D = { "####.", "#...#", "#...#", "#...#", "#...#", "#...#", "####." },
  E = { "#####", "#....", "#....", "####.", "#....", "#....", "#####" },
  A = { ".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#" },
  Z = { "#####", "....#", "...#.", "..#..", ".#...", "#....", "#####" },
  O = { ".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###." },
  N = { "#...#", "##..#", "#.#.#", "#..##", "#...#", "#...#", "#...#" },
}

----------------------------------------------------------------------- scenery object
function Sc.new(scr, G, P)
  local self = {}
  local PW, PH = scr.PW, scr.PH
  local N = P.N
  local W_, O_, Y_, D_, A_, R_, K_ = 0, 1, 4, 7, 8, 14, 15
  local SKY1, SKY2, SKY3, SKY4, FAR, NEAR, FACE = N.SKY1, N.SKY2, N.SKY3, N.SKY4, N.FAR, N.NEAR, N.FACE
  self.FACE = FACE

  -- deterministic random numbers (same skyline every time)
  local seed = 1234
  local function rnd() seed = (seed * 1103515245 + 12345) % 2147483648; return seed / 2147483648 end

  -- skylines: building top height per column + lit window blocks
  local function makeSkyline(period, wmin, wmax, hmin, hmax, windows)
    local top, wins = {}, {}
    local x = 0
    while x < period do
      local w = floor(wmin + rnd() * (wmax - wmin))
      local h = floor(hmin + rnd() * (hmax - hmin))
      local broken = rnd() < 0.5
      local bstart, bdepth = floor(rnd() * w), floor(4 + rnd() * 10)
      local lit = windows and rnd() < 0.4
      local minH = h
      for i = 0, w - 1 do
        if x + i < period then
          local hh = h
          if broken and i >= bstart then hh = h - floor(bdepth * (i - bstart + 1) / (w - bstart + 1) + (rnd() < 0.4 and 2 or 0)) end
          if i == 0 or i == w - 1 then hh = hh - 1 end
          top[x + i] = hh
          if hh < minH then minH = hh end
        end
      end
      if lit then
        for wx = x + 2, x + w - 4, 4 do
          for wy = 7, minH - 5, 6 do
            if wx + 1 < period and rnd() < 0.13 then
              wins[#wins + 1] = { wx, -wy, (rnd() < 0.15) and Y_ or O_, rnd() < 0.08 }
            end
          end
        end
      end
      if rnd() < 0.3 then local ax = x + floor(w / 2); if ax < period then top[ax] = (top[ax] or 0) + 7 end end
      x = x + w + (rnd() < 0.3 and floor(rnd() * 5) or 0)
    end
    for i = 0, period - 1 do top[i] = top[i] or 0 end
    return { top = top, wins = wins, period = period }
  end
  local farS = makeSkyline(512, 14, 34, 22, 58, false)
  local nearS = makeSkyline(640, 22, 46, 34, 92, true)

  local stars = {}
  for i = 1, 70 do stars[i] = { floor(rnd() * 900), floor(rnd() * 120), (rnd() < 0.25) and W_ or A_, floor(rnd() * 40) } end
  local embers = {}
  for i = 1, 46 do
    embers[i] = { rnd() * 700, rnd() * 300, 0.25 + rnd() * 0.5, rnd() * 6.28, (rnd() < 0.6) and O_ or ((rnd() < 0.5) and Y_ or R_) }
  end

  -- blood moon pixels
  local moon = {}
  for yy = -13, 13 do
    for xx = -13, 13 do
      if xx * xx + yy * yy <= 160 then
        local col = R_
        if (xx - 4) ^ 2 + (yy - 4) ^ 2 > 200 then col = O_ end
        if (xx - 3) ^ 2 + (yy - 2) ^ 2 <= 7 or (xx + 6) ^ 2 + (yy - 6) ^ 2 <= 4 or (xx + 2) ^ 2 + (yy + 7) ^ 2 <= 3
          or (xx - 7) ^ 2 + (yy + 3) ^ 2 <= 2 then col = SKY4 end
        moon[#moon + 1] = { xx, yy, col }
      end
    end
  end

  -- sky gradient (ordered dither between bands)
  local EDGES = { { 22, SKY1, SKY2 }, { 64, SKY2, SKY3 }, { 108, SKY3, SKY4 } }
  local BAYER = { [0] = { [0] = 0, 8, 2, 10 }, { [0] = 12, 4, 14, 6 }, { [0] = 3, 11, 1, 9 }, { [0] = 15, 7, 13, 5 } }
  local RAMP = 14
  local function skyAt(x, y)
    local c = SKY1
    for i = 1, 3 do
      local e = EDGES[i]
      if y >= e[1] + RAMP then c = e[3]
      elseif y >= e[1] then
        c = (BAYER[y % 4][x % 4] < (y - e[1] + 0.5) / RAMP * 16) and e[3] or e[2]
        break
      else break end
    end
    return c
  end

  local patCache = {}
  local function pat(a, b, c, d, e, f)
    local k = a + b * 16 + c * 256 + d * 4096 + e * 65536 + f * 1048576
    local p = patCache[k]
    if not p then p = G.pattern({ a, b, c, d, e, f }); patCache[k] = p end
    return p
  end
  local skyCell = {}
  local solidNear = pat(NEAR, NEAR, NEAR, NEAR, NEAR, NEAR)
  local solidFar = pat(FAR, FAR, FAR, FAR, FAR, FAR)

  local nearLine, farLine = {}, {}
  local cells = {}
  local lastKey = nil
  local CW = scr.CW
  local nOff, nBase, fOff, fBase, sOff = 0, 0, 0, 0, 0

  local function px(x, y)
    if y >= nearLine[x] then return NEAR end
    if y >= farLine[x] then return FAR end
    return skyAt(x, y + sOff)
  end

  local function build()
    for x = 0, PW - 1 do
      nearLine[x] = nBase - nearS.top[(x + nOff) % nearS.period]
      farLine[x] = fBase - farS.top[(x + fOff) % farS.period]
    end
    local i = 0
    for cy = 0, scr.CH - 1 do
      local y0 = cy * 3
      local y2 = y0 + 2
      for cx = 0, CW - 1 do
        i = i + 1
        local x = cx * 2
        local na, nb, fa, fb = nearLine[x], nearLine[x + 1], farLine[x], farLine[x + 1]
        local p
        if y0 >= na and y0 >= nb then p = solidNear
        elseif y2 < na and y2 < nb then
          if y2 < fa and y2 < fb then
            local k = (cx % 2) * 100000 + y0 + sOff
            p = skyCell[k]
            if not p then
              local sy = y0 + sOff
              p = pat(skyAt(x, sy), skyAt(x + 1, sy), skyAt(x, sy + 1), skyAt(x + 1, sy + 1), skyAt(x, sy + 2), skyAt(x + 1, sy + 2))
              skyCell[k] = p
            end
          elseif y0 >= fa and y0 >= fb then p = solidFar
          end
        end
        if not p then
          p = pat(px(x, y0), px(x + 1, y0), px(x, y0 + 1), px(x + 1, y0 + 1), px(x, y2), px(x + 1, y2))
        end
        cells[i] = p
      end
    end
  end

  local function getCell(cx, cy) return cells[cy * CW + cx + 1] end

  -- full background for camera position (camX, camY in pixels)
  function self.background(camX, camY, frame)
    nOff, nBase = floor(camX * 0.5), floor(PH * 0.914 - camY * 0.32)
    fOff, fBase = floor(camX * 0.25), floor(PH * 0.807 - camY * 0.16)
    sOff = floor(camY * 0.04)
    local key = nOff .. ":" .. nBase .. ":" .. fOff .. ":" .. fBase .. ":" .. sOff
    if key ~= lastKey then build(); lastKey = key end
    scr.fillBase(getCell)
    -- moon
    local mx, my = floor(PW * 0.8 - camX * 0.03), floor(36 - camY * 0.03)
    for i = 1, #moon do local m = moon[i]; scr.pixel(mx + m[1], my + m[2], m[3]) end
    -- stars (only where the sky shows)
    for i = 1, #stars do
      local s = stars[i]
      local x = floor((s[1] - camX * 0.1) % 900)
      local y = floor(s[2] - camY * 0.06)
      if x < PW and y >= 0 and (frame + s[4]) % 40 ~= 0 and y < farLine[x] and y < nearLine[x] then scr.pixel(x, y, s[3]) end
    end
    -- lit windows
    local wins = nearS.wins
    for i = 1, #wins do
      local w = wins[i]
      local x = (w[1] - nOff) % nearS.period
      if x < PW - 1 and not (w[4] and (floor(frame / 7) + i) % 5 == 0) then
        local y = nBase + w[2]
        scr.pixel(x, y, w[3]); scr.pixel(x + 1, y, w[3]); scr.pixel(x, y + 1, w[3]); scr.pixel(x + 1, y + 1, w[3])
      end
    end
  end

  function self.embers(camX, camY, frame)
    for i = 1, #embers do
      local e = embers[i]
      local y = (e[2] - frame * e[3] - camY * 0.45) % 300 - 20
      local x = (e[1] + sin(frame * 0.05 + e[4]) * 6 - camX * 0.7) % 700
      if x < PW and y < PH then
        scr.pixel(x, y, e[5])
        if e[3] > 0.6 then scr.pixel(x, y + 1, R_) end
      end
    end
  end

  -------------------------------------------------------------------- frames + panels
  local function hline(x1, x2, y, c) for x = x1, x2 do scr.pixel(x, y, c) end end
  local function vline(x, y1, y2, c) for y = y1, y2 do scr.pixel(x, y, c) end end

  -- pixel frame around a box given in pixels (x0, y0, w, h); the line runs
  -- through the inner side of the outermost cells, corners are rounded
  function self.frame(x0, y0, w, h, col, double, studs, col2)
    hline(x0 + 2, x0 + w - 3, y0 + 2, col); hline(x0 + 2, x0 + w - 3, y0 + h - 3, col)
    vline(x0 + 1, y0 + 3, y0 + h - 4, col); vline(x0 + w - 2, y0 + 3, y0 + h - 4, col)
    if double then
      local c2 = col2 or col
      hline(x0 + 3, x0 + w - 4, y0 + 1, c2); hline(x0 + 3, x0 + w - 4, y0 + h - 2, c2)
      vline(x0, y0 + 4, y0 + h - 5, c2); vline(x0 + w - 1, y0 + 4, y0 + h - 5, c2)
    end
    if studs then
      scr.pixel(x0 + 1, y0 + 2, studs); scr.pixel(x0 + w - 2, y0 + 2, studs)
      scr.pixel(x0 + 1, y0 + h - 3, studs); scr.pixel(x0 + w - 2, y0 + h - 3, studs)
    end
  end

  -- text panel: interior cells x..x+w-1, y..y+h-1 (1-based text cells),
  -- frame drawn in the cells around it
  -- hole = number of columns on the left kept as pixels (for a big icon)
  function self.panel(x, y, w, h, col, double, hole)
    hole = hole or 0
    if hole > 0 then scr.rect((x - 1) * 2, (y - 1) * 3, hole * 2, h * 3, FACE) end
    local blank = (" "):rep(w - hole)
    for yy = y, y + h - 1 do scr.text(x + hole, yy, blank, W_, FACE) end
    self.frame((x - 2) * 2, (y - 2) * 3, (w + 2) * 2, (h + 2) * 3, col, double)
  end

  function self.icon(name, x, y, col, scale)
    local p = Sc.ICON[name] or Sc.ICON.star
    scale = scale or 1
    for i = 1, #p, 2 do
      if scale == 1 then scr.pixel(x + p[i], y + p[i + 1], col)
      else scr.rect(x + p[i] * scale, y + p[i + 1] * scale, scale, scale, col) end
    end
  end

  -------------------------------------------------------------------- logo
  local LOGO_S = 3
  local logoPx, logoW, logoH = {}, 0, 7 * LOGO_S
  do
    local word = "DEAD ZONE"
    local x = 0
    for i = 1, #word do
      local ch = word:sub(i, i)
      if ch == " " then x = x + 4 * LOGO_S
      else
        local f = FONT[ch]
        for fy = 1, 7 do
          for fx = 1, 5 do
            if f[fy]:sub(fx, fx) == "#" then
              for sy = 0, LOGO_S - 1 do
                for sx = 0, LOGO_S - 1 do logoPx[#logoPx + 1] = { x + (fx - 1) * LOGO_S + sx, (fy - 1) * LOGO_S + sy } end
              end
            end
          end
        end
        x = x + 6 * LOGO_S
      end
    end
    logoW = x - LOGO_S
  end
  -- blood drips: columns along the bottom edge of the letters
  local drips = {}
  do
    local bottom = {}
    for _, p in ipairs(logoPx) do if p[2] == logoH - 1 then bottom[#bottom + 1] = p[1] end end
    for i = 1, #bottom, 1 do
      if rnd() < 0.12 then drips[#drips + 1] = { bottom[i], 2 + floor(rnd() * 7), rnd() * 60 } end
    end
  end
  self.logoW, self.logoH = logoW, logoH

  -- logo with top-left pixel (x, y)
  function self.logo(x, y, frame)
    for i = 1, #logoPx do
      local p = logoPx[i]
      scr.pixel(x + p[1] + 1, y + p[2] + 1, K_)  -- shadow
    end
    for i = 1, #logoPx do
      local p = logoPx[i]
      scr.pixel(x + p[1], y + p[2], (p[2] < LOGO_S - 1) and O_ or R_)
    end
    for i = 1, #drips do
      local d = drips[i]
      -- each drip slowly grows, falls off and starts again
      local t = (frame * 0.08 + d[3]) % 30
      local len = min(d[2], floor(t))
      for k = 0, len - 1 do scr.pixel(x + d[1], y + logoH + k, R_) end
      if t > d[2] and t < d[2] + 8 then scr.pixel(x + d[1], y + logoH + d[2] + floor((t - d[2]) * 2), R_) end
    end
  end

  return self
end

return Sc
