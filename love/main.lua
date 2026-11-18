-- DEAD ZONE for LÖVE (Android / desktop).
--
-- The game itself is the unchanged CC:Tweaked version (deadzone.lua + dz/).
-- This file pretends to be ComputerCraft: a monitor that receives the game's
-- teletext rows, the CC event loop (timers, keys), fs, textutils, peripherals.
-- Rows are decoded on the GPU by a small shader, and touch controls are
-- turned into the key events the game already understands.

local CW, CH = 164, 54            -- text cells the game draws into (2x3 pixels each); CW follows the screen shape
local IS_MOBILE = love.system.getOS() == "Android" or love.system.getOS() == "iOS"
_G.DZ_TOUCH = IS_MOBILE or os.getenv("DZ_TOUCH") ~= nil   -- game shows touch hints instead of key hints

---------------------------------------------------------------------- CC key codes
keys = {
  a = 30, b = 48, d = 32, h = 35, n = 49, p = 25, q = 16, r = 19, s = 31, t = 20, v = 47, w = 17, x = 45,
  one = 2, two = 3, three = 4, four = 5, space = 57, enter = 28, tab = 15, backspace = 14,
  up = 200, down = 208, left = 203, right = 205, e = 18, f = 33,
}
local LOVEKEY = {
  ["return"] = keys.enter, kpenter = keys.enter, ["1"] = keys.one, ["2"] = keys.two, ["3"] = keys.three, ["4"] = keys.four,
}
for name, code in pairs(keys) do if #name == 1 then LOVEKEY[name] = code end end
LOVEKEY.space, LOVEKEY.tab, LOVEKEY.backspace = keys.space, keys.tab, keys.backspace
LOVEKEY.up, LOVEKEY.down, LOVEKEY.left, LOVEKEY.right = keys.up, keys.down, keys.left, keys.right

colours = { white = 1, orange = 2, magenta = 4, lightBlue = 8, yellow = 16, lime = 32, pink = 64, grey = 128,
  lightGrey = 256, cyan = 512, purple = 1024, blue = 2048, brown = 4096, green = 8192, red = 16384, black = 32768 }
colours.gray, colours.lightGray = colours.grey, colours.lightGrey
colors = colours

---------------------------------------------------------------------- screen (fake monitor)
local cellData
local cellImg, palData, palImg, glyphs, shader
local cellsDirty = true
local palette = {}
for i = 0, 15 do palette[i] = { 0, 0, 0 } end

local mon = {}
local curX, curY = 1, 1
local function hexv(c)
  local b = c:byte()
  return (b >= 97) and (b - 87) or (b - 48)
end
function mon.getSize() return CW, CH end
function mon.isColour() return true end
mon.isColor = mon.isColour
function mon.setTextScale() end
function mon.setCursorPos(x, y) curX, curY = x, y end
function mon.setBackgroundColour() end
mon.setBackgroundColor = mon.setBackgroundColour
function mon.setTextColour() end
mon.setTextColor = mon.setTextColour
function mon.clear()
  cellData:mapPixel(function() return 32 / 255, 0, 15 / 255, 1 end)
  cellsDirty = true
end
function mon.write() end
function mon.blit(text, fg, bg)
  local y = curY - 1
  if y < 0 or y >= CH then return end
  local x0 = curX - 1
  for i = 1, #text do
    local x = x0 + i - 1
    if x >= 0 and x < CW then
      cellData:setPixel(x, y, text:byte(i) / 255, hexv(fg:sub(i, i)) / 255, hexv(bg:sub(i, i)) / 255, 1)
    end
  end
  cellsDirty = true
end
function mon.setPaletteColour(col, r, g, b)
  local slot = math.floor(math.log(col) / math.log(2) + 0.5)
  if type(r) == "number" and g == nil then   -- 0xRRGGBB form
    r, g, b = math.floor(r / 65536) % 256 / 255, math.floor(r / 256) % 256 / 255, r % 256 / 255
  end
  palette[slot] = { r, g, b }
  if palData then palData:setPixel(slot, 0, r, g, b, 1); palImg:replacePixels(palData) end
end
mon.setPaletteColor = mon.setPaletteColour
function mon.getPaletteColour(col)
  local p = palette[math.floor(math.log(col) / math.log(2) + 0.5)]
  return p[1], p[2], p[3]
end
mon.getPaletteColor = mon.getPaletteColour

term = {
  current = function() return mon end,
  nativePaletteColour = function() return 0.5, 0.5, 0.5 end,
}
term.nativePaletteColor = term.nativePaletteColour

peripheral = {
  find = function(kind, filter)
    if kind == "monitor" and (not filter or filter("top", mon)) then return mon end
    return nil
  end,
  getNames = function() return { "top" } end,
  getType = function(n) if n == "top" then return "monitor" end end,
  wrap = function(n) if n == "top" then return mon end end,
}

---------------------------------------------------------------------- fs + textutils
local function norm(p) return (p:gsub("^/+", ""):gsub("//+", "/")) end
fs = {}
function fs.getDir(p) return (p:match("^(.*)/[^/]*$") or "") end
function fs.exists(p) return love.filesystem.getInfo(norm(p)) ~= nil end
function fs.makeDir(p) love.filesystem.createDirectory(norm(p)) end
function fs.list(p) return love.filesystem.getDirectoryItems(norm(p)) end
function fs.open(p, mode)
  p = norm(p)
  if mode == "r" then
    local data = love.filesystem.read(p)
    if not data then return nil end
    return { readAll = function() return data end, close = function() end }
  end
  local buf = {}
  return {
    write = function(s) buf[#buf + 1] = tostring(s) end,
    writeLine = function(s) buf[#buf + 1] = tostring(s) .. "\n" end,
    flush = function() love.filesystem.write(p, table.concat(buf)) end,
    close = function() love.filesystem.write(p, table.concat(buf)) end,
  }
end

local function ser(v, ind)
  local t = type(v)
  if t == "table" then
    local out = {}
    for k, x in pairs(v) do
      local key = (type(k) == "string" and k:match("^[%a_][%w_]*$")) and k or ("[" .. ser(k) .. "]")
      out[#out + 1] = key .. " = " .. ser(x)
    end
    return "{ " .. table.concat(out, ", ") .. " }"
  elseif t == "string" then return string.format("%q", v)
  else return tostring(v) end
end
textutils = {
  serialize = ser, serialise = ser,
  unserialize = function(s)
    local f = loadstring("return " .. s, "unser")
    if not f then return nil end
    setfenv(f, {})
    local ok, r = pcall(f)
    return ok and r or nil
  end,
}
textutils.unserialise = textutils.unserialize

shell = { getRunningProgram = function() return "deadzone.lua" end }

---------------------------------------------------------------------- CC event loop
local queue = {}
local timers, nextTimer, now = {}, 0, 0
local game, gameDone, crash = nil, false, nil

function os.startTimer(t) nextTimer = nextTimer + 1; timers[nextTimer] = now + (t or 0); return nextTimer end
function os.cancelTimer(id) timers[id] = nil end
function os.queueEvent(...) queue[#queue + 1] = { ... } end
function os.pullEventRaw() return coroutine.yield() end
os.pullEvent = os.pullEventRaw
function os.epoch() return math.floor(love.timer.getTime() * 1000) end
function sleep(t)
  local id = os.startTimer(t)
  repeat local e, a = coroutine.yield() until e == "timer" and a == id
end
parallel = { waitForAny = function(a) a() end, waitForAll = function(a) a() end }
printError = function(e) crash = tostring(e); io.stderr:write(tostring(e) .. "\n") end

local function resume(...)
  if gameDone then return end
  local ok, err = coroutine.resume(game, ...)
  if not ok then crash = tostring(err); gameDone = true; io.stderr:write(crash .. "\n") end
  if coroutine.status(game) == "dead" then gameDone = true end
end

local function sendKey(code)
  queue[#queue + 1] = { "key", code, false }
end
local function releaseKey(code)
  queue[#queue + 1] = { "key_up", code }
end
local function tapKey(code) sendKey(code); releaseKey(code) end

---------------------------------------------------------------------- GPU decode of the teletext cells
local SHADER = [[
uniform Image glyphs;
uniform Image pal;
uniform vec2 grid;
vec3 P(float i) { return Texel(pal, vec2((i + 0.5) / 16.0, 0.5)).rgb; }
vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
  vec2 cp = tc * grid;
  vec2 ci = floor(cp);
  vec2 f = clamp(cp - ci, 0.0, 0.999);
  vec4 d = Texel(tex, (ci + 0.5) / grid);
  float ch = floor(d.r * 255.0 + 0.5);
  vec3 fg = P(floor(d.g * 255.0 + 0.5));
  vec3 bg = P(floor(d.b * 255.0 + 0.5));
  vec3 col = bg;
  if (ch >= 128.0 && ch < 160.0) {
    float bits = ch - 128.0;
    float idx = floor(f.y * 3.0) * 2.0 + floor(f.x * 2.0);
    if (idx < 4.5) {
      float on = mod(floor((bits + 0.5) / exp2(idx)), 2.0);
      if (on > 0.5) col = fg;
    }
  } else if (ch > 32.0 && ch < 127.0) {
    float g = ch - 32.0;
    vec2 gp = vec2(mod(g, 16.0), floor(g / 16.0));
    float a = Texel(glyphs, (gp + f) / vec2(16.0, 6.0)).a;
    col = mix(bg, fg, a);
  }
  return vec4(col, 1.0) * color;
}
]]

local GW, GH = 24, 36
local function buildGlyphs()
  local font = love.graphics.newFont(30)
  local c = love.graphics.newCanvas(16 * GW, 6 * GH)
  love.graphics.setCanvas(c)
  love.graphics.clear(0, 0, 0, 0)
  love.graphics.setFont(font)
  love.graphics.setColor(1, 1, 1, 1)
  for code = 33, 126 do
    local g = code - 32
    local gx, gy = g % 16, math.floor(g / 16)
    local s = string.char(code)
    local w = font:getWidth(s)
    local sx = math.min(1, (GW - 2) / math.max(1, w))
    love.graphics.print(s, gx * GW + (GW - w * sx) / 2, gy * GH + (GH - font:getHeight()) / 2, 0, sx, 1)
  end
  love.graphics.setCanvas()
  c:setFilter("linear", "linear")
  return c
end

---------------------------------------------------------------------- layout + touch controls
local W, H, scale, gx, gy, gw, gh = 0, 0, 1, 0, 0, 0, 0
local uiFont, smallFont
local function layout()
  W, H = love.graphics.getDimensions()
  scale = math.min(W / (CW * 2), H / (CH * 3))
  gw, gh = CW * 2 * scale, CH * 3 * scale
  gx, gy = math.floor((W - gw) / 2), math.floor((H - gh) / 2)
  uiFont = love.graphics.newFont(math.max(12, math.floor(H * 0.032)))
  smallFont = love.graphics.newFont(math.max(10, math.floor(H * 0.024)))
end

-- sticks: id -> { kind = "move"/"aim", ox, oy, x, y, held = {codes} }
local sticks = {}
local STICK_KEYS = {
  move = { keys.w, keys.a, keys.s, keys.d },
  aim = { keys.up, keys.left, keys.down, keys.right },
}
local function stickRadius() return H * 0.14 end

local function setHeld(st, want)
  for code in pairs(st.held) do if not want[code] then releaseKey(code); st.held[code] = nil end end
  for code in pairs(want) do if not st.held[code] then sendKey(code); st.held[code] = true end end
end
local function updateStick(st)
  local dx, dy = st.x - st.ox, st.y - st.oy
  local d = math.sqrt(dx * dx + dy * dy)
  local R = stickRadius()
  local want = {}
  if d > R * 0.22 then
    local k = STICK_KEYS[st.kind]   -- up, left, down, right
    local nx, ny = dx / d, dy / d
    if ny < -0.38 then want[k[1]] = true elseif ny > 0.38 then want[k[3]] = true end
    if nx < -0.38 then want[k[2]] = true elseif nx > 0.38 then want[k[4]] = true end
  end
  setHeld(st, want)
end

-- context buttons for each game state
local function button(label, key, x, y, w, h, invisible)
  return { label = label, key = key, x = x, y = y, w = w, h = h, invisible = invisible }
end
local function buttonsFor(state)
  local B = {}
  local bh = H * 0.11
  local bw = math.max(H * 0.26, 110)
  local pad = H * 0.02
  local rx = W - bw - pad
  local function col(list, x)
    local y = pad
    for _, e in ipairs(list) do B[#B + 1] = button(e[1], e[2], x, y, bw, bh); y = y + bh + pad end
  end
  if state == "play" then
    -- pause under the HUD strip; weapons = the game's own slot boxes at the bottom
    local s = bh * 0.9
    B[#B + 1] = button("II", keys.p, gx + pad, gy + 12 * scale + pad, s, s)
    local slotW, gap = 12, 2
    local total = 4 * slotW + 3 * gap
    local sx0 = math.floor((CW - total) / 2) + 1
    for i = 1, 4 do
      local cx = sx0 + (i - 1) * (slotW + gap) - 2
      B[#B + 1] = button("", keys[({ "one", "two", "three", "four" })[i]], gx + (cx - 1) * 2 * scale, gy + (CH - 4) * 3 * scale,
        (slotW + 2) * 2 * scale, 4 * 3 * scale, true)
    end
  end
  return B
end

local pressedBtn = {}   -- touch id -> button
local lastState = nil
local function hitButton(x, y)
  for _, b in ipairs(buttonsFor(_G.DZ_STATE or "title")) do
    if x >= b.x and x <= b.x + b.w and y >= b.y and y <= b.y + b.h then return b end
  end
end

local function pointerDown(id, x, y)
  local st = _G.DZ_STATE or "title"
  local b = hitButton(x, y)
  if b then
    pressedBtn[id] = b
    tapKey(b.key)
    if st == "naming" then love.keyboard.setTextInput(false) end
    return
  end
  if st == "play" then
    sticks[id] = { kind = (x < W / 2) and "move" or "aim", ox = x, oy = y, x = x, y = y, held = {} }
    return
  end
  -- taps on the game picture: send a CC mouse_click in text cells (cards, etc.)
  if x >= gx and x < gx + gw and y >= gy and y < gy + gh then
    local cx = math.floor((x - gx) / (2 * scale)) + 1
    local cy = math.floor((y - gy) / (3 * scale)) + 1
    queue[#queue + 1] = { "mouse_click", 1, cx, cy }
  end
  if st == "naming" then love.keyboard.setTextInput(true) end
end
local function pointerMove(id, x, y)
  local s = sticks[id]
  if s then
    local R = stickRadius()
    local dx, dy = x - s.ox, y - s.oy
    local d = math.sqrt(dx * dx + dy * dy)
    if d > R then s.ox, s.oy = x - dx / d * R, y - dy / d * R end   -- base follows the thumb
    s.x, s.y = x, y
    updateStick(s)
  end
end
local function pointerUp(id)
  local s = sticks[id]
  if s then setHeld(s, {}); sticks[id] = nil end
  pressedBtn[id] = nil
end

---------------------------------------------------------------------- LÖVE callbacks
function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")
  local sw, sh = love.graphics.getDimensions()
  if sw < sh then sw, sh = sh, sw end   -- always landscape
  CW = math.max(128, math.min(200, math.floor(CH * 3 * sw / sh / 2)))
  cellData = love.image.newImageData(CW, CH)
  layout()
  palData = love.image.newImageData(16, 1)
  for i = 0, 15 do local p = palette[i]; palData:setPixel(i, 0, p[1], p[2], p[3], 1) end
  palImg = love.graphics.newImage(palData)
  palImg:setFilter("nearest", "nearest")
  mon.clear()
  cellImg = love.graphics.newImage(cellData)
  cellImg:setFilter("nearest", "nearest")
  glyphs = buildGlyphs()
  shader = love.graphics.newShader(SHADER)
  shader:send("grid", { CW, CH })
  shader:send("glyphs", glyphs)
  shader:send("pal", palImg)
  love.keyboard.setKeyRepeat(false)
  if _G.DZ_LOVE_HOOK then _G.DZ_LOVE_HOOK() end
  game = coroutine.create(function()
    local chunk = assert(love.filesystem.load("deadzone.lua"))
    chunk()
  end)
  resume()
end

function love.resize() layout() end

function love.update(dt)
  now = now + math.min(dt, 0.25)
  if gameDone then return end
  if _G.DZ_LOVE_TICK then _G.DZ_LOVE_TICK(dt) end
  -- on-screen keyboard only while typing a name
  if _G.DZ_STATE ~= lastState then
    if _G.DZ_STATE == "naming" then love.keyboard.setTextInput(true)
    elseif lastState == "naming" then love.keyboard.setTextInput(false) end
    -- drop held stick keys when leaving play
    if lastState == "play" then for id, s in pairs(sticks) do setHeld(s, {}); sticks[id] = nil end end
    lastState = _G.DZ_STATE
  end
  -- deliver queued input, then due timers (the game draws one frame per timer)
  local guard = 0
  while #queue > 0 and not gameDone and guard < 64 do
    guard = guard + 1
    resume(unpack(table.remove(queue, 1)))
  end
  local fired = 0
  for id, t in pairs(timers) do
    if t <= now and fired < 2 then
      timers[id] = nil
      fired = fired + 1
      resume("timer", id)
      if gameDone then break end
    end
  end
  if gameDone and not crash then love.event.quit() end
end

local function drawButton(b, active)
  love.graphics.setColor(0, 0, 0, active and 0.75 or 0.5)
  love.graphics.rectangle("fill", b.x, b.y, b.w, b.h, 10, 10)
  love.graphics.setColor(1, 1, 1, active and 1 or 0.8)
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", b.x, b.y, b.w, b.h, 10, 10)
  love.graphics.setFont(uiFont)
  local fh = uiFont:getHeight()
  love.graphics.printf(b.label, b.x, b.y + (b.h - fh) / 2, b.w, "center")
end

function love.draw()
  love.graphics.clear(0.03, 0.03, 0.04)
  if cellsDirty then cellImg:replacePixels(cellData); cellsDirty = false end
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setShader(shader)
  love.graphics.draw(cellImg, gx, gy, 0, gw / CW, gh / CH)
  love.graphics.setShader()

  local st = _G.DZ_STATE or "title"
  -- sticks
  if st == "play" then
    local R = stickRadius()
    local hint = { move = { R * 1.35, H - R * 1.35 }, aim = { W - R * 1.35, H - R * 1.35 } }
    local active = {}
    for _, s in pairs(sticks) do active[s.kind] = s end
    for _, kind in ipairs({ "move", "aim" }) do
      local s = active[kind]
      local ox, oy = hint[kind][1], hint[kind][2]
      local kx, ky = ox, oy
      if s then ox, oy, kx, ky = s.ox, s.oy, s.x, s.y end
      local dx, dy = kx - ox, ky - oy
      local d = math.sqrt(dx * dx + dy * dy)
      if d > R then kx, ky = ox + dx / d * R, oy + dy / d * R end
      -- base: dark disc, bright rim, 8 notches
      love.graphics.setColor(0, 0, 0, s and 0.35 or 0.2)
      love.graphics.circle("fill", ox, oy, R)
      love.graphics.setLineWidth(math.max(2, R * 0.05))
      love.graphics.setColor(1, 1, 1, s and 0.55 or 0.25)
      love.graphics.circle("line", ox, oy, R)
      for k = 0, 7 do
        local a = k * math.pi / 4
        love.graphics.line(ox + math.cos(a) * R * 0.8, oy + math.sin(a) * R * 0.8, ox + math.cos(a) * R * 0.92, oy + math.sin(a) * R * 0.92)
      end
      -- knob: coloured cap with a highlight
      local r1, g1, b1 = 0.36, 0.62, 0.95
      if kind == "aim" then r1, g1, b1 = 0.95, 0.45, 0.2 end
      love.graphics.setColor(0, 0, 0, s and 0.5 or 0.25)
      love.graphics.circle("fill", kx + R * 0.04, ky + R * 0.06, R * 0.4)
      love.graphics.setColor(r1, g1, b1, s and 0.95 or 0.45)
      love.graphics.circle("fill", kx, ky, R * 0.38)
      love.graphics.setColor(1, 1, 1, s and 0.45 or 0.2)
      love.graphics.circle("fill", kx - R * 0.1, ky - R * 0.1, R * 0.14)
      if not s then
        love.graphics.setFont(smallFont)
        love.graphics.setColor(1, 1, 1, 0.35)
        love.graphics.printf(kind == "move" and "MOVE" or "AIM + SHOOT", ox - R, oy + R + 4, 2 * R, "center")
      end
    end
  end
  -- buttons
  local pressed = {}
  for _, b in pairs(pressedBtn) do pressed[b.label] = true end
  for _, b in ipairs(buttonsFor(st)) do if not b.invisible then drawButton(b, pressed[b.label]) end end

  if crash then
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", 0, 0, W, H)
    love.graphics.setColor(1, 0.4, 0.4, 1)
    love.graphics.setFont(smallFont)
    love.graphics.printf("DEAD ZONE crashed:\n\n" .. crash, 20, 20, W - 40)
  end
  if _G.DZ_LOVE_DRAWN then _G.DZ_LOVE_DRAWN() end
end

function love.touchpressed(id, x, y) pointerDown(id, x, y) end
function love.touchmoved(id, x, y) pointerMove(id, x, y) end
function love.touchreleased(id) pointerUp(id) end
-- the mouse acts as one finger on desktop
function love.mousepressed(x, y, b, istouch) if not istouch then pointerDown("mouse", x, y) end end
function love.mousemoved(x, y, dx, dy, istouch) if not istouch then pointerMove("mouse", x, y) end end
function love.mousereleased(x, y, b, istouch) if not istouch then pointerUp("mouse") end end

function love.keypressed(key, sc, isrepeat)
  if key == "escape" and IS_MOBILE then   -- Android back button: pause / go back
    local st = _G.DZ_STATE
    if st == "play" then tapKey(keys.p) elseif st ~= "title" then tapKey(keys.q) end
    return
  end
  local code = LOVEKEY[key]
  if code then queue[#queue + 1] = { "key", code, isrepeat } end
end
function love.keyreleased(key)
  local code = LOVEKEY[key]
  if code then queue[#queue + 1] = { "key_up", code } end
end
function love.textinput(t) queue[#queue + 1] = { "char", t } end
