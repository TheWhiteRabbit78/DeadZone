-- DEAD ZONE player profiles: one save file per Minecraft name + leaderboard.
-- Files live in <install dir>/saves/<name>.dat
-- Tip: `label set deadzone` on the computer so saves survive if it gets picked up.

local Prof = {}
local DIR = "/deadzone/saves/"

local DEFAULTS = {
  souls = 0, soulsTotal = 0, tree = {}, prestige = 0,
  best = 0, bestTime = 0, runs = 0, kills = 0, bosses = 0,
}

function Prof.init(dir)
  DIR = "/" .. dir .. "/saves/"
  if not fs.exists(DIR) then fs.makeDir(DIR) end
end

function Prof.clean(name)
  return ((name or ""):gsub("[^%w_%-]", "")):sub(1, 16)
end

function Prof.load(name)
  name = Prof.clean(name)
  if name == "" then name = "Guest" end
  local p = { name = name }
  local path = DIR .. name .. ".dat"
  if fs.exists(path) then
    local f = fs.open(path, "r")
    local ok, t = pcall(textutils.unserialize, f.readAll())
    f.close()
    if ok and type(t) == "table" then
      for k, v in pairs(t) do p[k] = v end
    end
  end
  for k, v in pairs(DEFAULTS) do
    if p[k] == nil then p[k] = (type(v) == "table") and {} or v end
  end
  p.name = name
  return p
end

function Prof.save(p)
  local f = fs.open(DIR .. p.name .. ".dat", "w")
  f.write(textutils.serialize(p))
  f.close()
end

-- top n profiles by best score
function Prof.leaderboard(n)
  local list = {}
  if fs.exists(DIR) then
    for _, file in ipairs(fs.list(DIR)) do
      local name = file:match("^(.-)%.dat$")
      if name then
        local p = Prof.load(name)
        if (p.best or 0) > 0 then list[#list + 1] = p end
      end
    end
  end
  table.sort(list, function(a, b) return (a.best or 0) > (b.best or 0) end)
  local out = {}
  for i = 1, math.min(n, #list) do out[i] = list[i] end
  return out
end

return Prof
