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
