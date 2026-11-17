-- DEAD ZONE palette: 16 custom colours.
-- Each entry: sprite letter -> blit slot (0-15) + RGB.
-- Slot 0 stays "white-ish" and slot 15 "black" so normal text still reads well.

local P = {}

P.list = {
  -- letter, slot, r, g, b,  meaning
  { "W", 0,  236, 230, 210 }, -- bone / white / text
  { "O", 1,  232, 118,  30 }, -- orange (fire, fuse)
  { "N", 2,  138,  86,  52 }, -- brown cloth
  { "C", 3,   94, 230, 230 }, -- cyan (XP)
  { "Y", 4,  242, 211,  74 }, -- yellow (bullets, gold)
  { "g", 5,   88, 156,  68 }, -- light grass / leaf highlight
  { "S", 6,  227, 179, 138 }, -- skin
  { "D", 7,   64,  64,  64 }, -- dark grey
  { "A", 8,  128, 128, 128 }, -- grey (stone, metal)
  { "Z", 9,  138, 168, 106 }, -- zombie skin
  { "L", 10,  29,  61,  32 }, -- dark leaves
  { "U", 11,  58, 100, 200 }, -- player blue
  { "B", 12,  92,  59,  34 }, -- bark / wood
  { "G", 13,  46,  90,  44 }, -- ground grass
  { "R", 14, 200,  48,  44 }, -- red
  { "K", 15,  21,  21,  21 }, -- outline black
}

-- night palette for the menu screens (skill tree, title, notes, death).
-- Text slots keep their meaning (W O C Y g D A R K); the rest become sky,
-- skyline and card colours.
P.NIGHT = {
  { 0, 236, 230, 210 }, { 1, 232, 118, 30 }, { 2, 44, 28, 72 },  { 3, 94, 230, 230 },
  { 4, 242, 211, 74 },  { 5, 112, 204, 88 }, { 6, 88, 42, 94 },  { 7, 66, 58, 90 },
  { 8, 146, 138, 168 }, { 9, 146, 62, 94 },  { 10, 20, 14, 40 }, { 11, 38, 33, 60 },
  { 12, 42, 27, 64 },   { 13, 23, 15, 33 },  { 14, 214, 58, 52 }, { 15, 10, 8, 16 },
}
-- night slot names
P.N = { SKY1 = 10, SKY2 = 2, SKY3 = 6, SKY4 = 9, FAR = 12, NEAR = 13, FACE = 11 }

P.slot = {}    -- letter -> slot number
P.rgb = {}     -- slot -> {r,g,b}
for _, e in ipairs(P.list) do
  P.slot[e[1]] = e[2]
  P.rgb[e[2]] = { e[3], e[4], e[5] }
end

-- squared colour distance between two slots (used when a 2x3 cell has >2 colours)
P.dist = {}
for a = 0, 15 do
  P.dist[a] = {}
  for b = 0, 15 do
    local ca, cb = P.rgb[a], P.rgb[b]
    local dr, dg, db = ca[1] - cb[1], ca[2] - cb[2], ca[3] - cb[3]
    P.dist[a][b] = dr * dr + dg * dg + db * db
  end
end

-- switch the active palette ("day" = game, "night" = menus). Tables are
-- changed in place so gfx sees the new colour distances at once.
P.current = "day"
function P.use(which)
  local src = {}
  if which == "night" then
    for _, e in ipairs(P.NIGHT) do src[e[1]] = { e[2], e[3], e[4] } end
  else
    for _, e in ipairs(P.list) do src[e[2]] = { e[3], e[4], e[5] } end
  end
  for slot = 0, 15 do local c, n = P.rgb[slot], src[slot]; c[1], c[2], c[3] = n[1], n[2], n[3] end
  for a = 0, 15 do
    for b = 0, 15 do
      local ca, cb = P.rgb[a], P.rgb[b]
      local dr, dg, db = ca[1] - cb[1], ca[2] - cb[2], ca[3] - cb[3]
      P.dist[a][b] = dr * dr + dg * dg + db * db
    end
  end
  P.current = which
end

-- apply / restore on a terminal or monitor
function P.apply(t)
  for slot = 0, 15 do
    local c = P.rgb[slot]
    t.setPaletteColour(2 ^ slot, c[1] / 255, c[2] / 255, c[3] / 255)
  end
end

function P.restore(t)
  for slot = 0, 15 do
    local col = 2 ^ slot
    t.setPaletteColour(col, term.nativePaletteColour(col))
  end
end

return P
