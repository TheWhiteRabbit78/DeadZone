-- DEAD ZONE installer / updater
--   wget run https://raw.githubusercontent.com/TheWhiteRabbit78/DeadZone/main/install.lua
-- Re-run any time to update.

local REPO = "https://raw.githubusercontent.com/TheWhiteRabbit78/DeadZone/main/"
local DEST = "/deadzone/"
local FILES = {
  "dz/palette.lua",
  "dz/gfx.lua",
  "dz/sprites.lua",
  "dz/world.lua",
  "dz/items.lua",
  "dz/tree.lua",
  "dz/profile.lua",
  "dz/patchnotes.lua",
  "deadzone.lua",
  "speedtest.lua",
}
-- launchers created in the root folder: name -> program inside DEST
local LAUNCHERS = {
  deadzone = "deadzone.lua",
  speedtest = "speedtest.lua",
}

if not http then error("HTTP is disabled on this server", 0) end

term.setTextColour(colours.red)
print("DEAD ZONE installer")
term.setTextColour(colours.white)

-- GitHub caches ".../main/..." for ~5 minutes, so download from the latest
-- commit id instead: updates show up the moment they're pushed.
local base = REPO
local api = http.get("https://api.github.com/repos/TheWhiteRabbit78/DeadZone/commits/main",
  { ["Accept"] = "application/vnd.github.sha" })
if api then
  local sha = api.readAll():match("^%x+")
  api.close()
  if sha and #sha >= 7 then
    base = "https://raw.githubusercontent.com/TheWhiteRabbit78/DeadZone/" .. sha .. "/"
    print("Version " .. sha:sub(1, 7))
  end
end

local failed = 0
for _, f in ipairs(FILES) do
  write("  " .. f .. " ... ")
  local res, err = http.get(base .. f, nil, true)
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
  if not os.getComputerLabel() then
    os.setComputerLabel("deadzone")
    print("Labelled this computer 'deadzone' so saves survive if it's picked up.")
  end
  print("Done. Run: deadzone")
else
  print(failed .. " file(s) failed - try again.")
end
