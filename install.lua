-- DEAD ZONE installer / updater
--   wget run https://raw.githubusercontent.com/TheWhiteRabbit78/DeadZone/main/install.lua
-- Re-run any time to update.

local REPO = "https://raw.githubusercontent.com/TheWhiteRabbit78/DeadZone/main/"
local DEST = "/deadzone/"
local FILES = {
  "dz/palette.lua",
  "dz/gfx.lua",
  "dz/sprites.lua",
  "speedtest.lua",
}
-- launchers created in the root folder: name -> program inside DEST
local LAUNCHERS = {
  speedtest = "speedtest.lua",
}

if not http then error("HTTP is disabled on this server", 0) end

term.setTextColour(colours.red)
print("DEAD ZONE installer")
term.setTextColour(colours.white)

local bust = "?t=" .. os.epoch("utc")  -- skip GitHub's cache so updates show up right away
local failed = 0
for _, f in ipairs(FILES) do
  write("  " .. f .. " ... ")
  local res, err = http.get(REPO .. f .. bust, nil, true)
  if res then
    local data = res.readAll()
    res.close()
    local h = fs.open(DEST .. f, "wb")
    h.write(data)
    h.close()
    term.setTextColour(colours.lime); print("ok"); term.setTextColour(colours.white)
  else
    failed = failed + 1
    term.setTextColour(colours.red); print("FAILED " .. tostring(err)); term.setTextColour(colours.white)
  end
end

for name, prog in pairs(LAUNCHERS) do
  local h = fs.open("/" .. name .. ".lua", "w")
  h.write('shell.run("' .. DEST .. prog .. '", ...)\n')
  h.close()
end

if failed == 0 then
  print("Done. Run: speedtest")
else
  print(failed .. " file(s) failed - try again.")
end
