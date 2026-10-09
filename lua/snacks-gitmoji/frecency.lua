-- Frecency scoring: emoji used more often and more recently rank higher.
-- Ported from olacin/telescope-gitmoji.nvim's frecency algorithm, persisted
-- to this plugin's own data file so it does not collide with that plugin's.

local M = {}

local MAX_TIMESTAMPS = 10
local RECENCY_MODIFIER = {
  { age = 240, value = 100 }, -- past 4 hours
  { age = 1440, value = 80 }, -- past day
  { age = 4320, value = 60 }, -- past 3 days
  { age = 10080, value = 40 }, -- past week
  { age = 43200, value = 20 }, -- past month
  { age = 129600, value = 10 }, -- past 90 days
}

local filename = vim.fn.stdpath("data") .. "/snacks-gitmoji-data.json"

local emoji_data

function M._init()
  if emoji_data ~= nil then
    return
  end
  if vim.fn.filereadable(filename) == 1 then
    local fd = io.open(filename, "r")
    if fd == nil then
      emoji_data = {}
      M._write()
      return
    end
    local json = fd:read("*a")
    fd:close()
    local ok = pcall(function()
      emoji_data = vim.json.decode(json)
    end)
    if (not ok) or type(emoji_data) ~= "table" then
      emoji_data = {}
    end
  else
    emoji_data = {}
    M._write()
  end
end

function M._write()
  local fd = io.open(filename, "w")
  if fd == nil then
    vim.notify("snacks-gitmoji: failed opening file for writing: " .. filename, vim.log.levels.WARN)
    return
  end
  fd:write(vim.json.encode(emoji_data))
  fd:close()
end

---Record a use of the given emoji so it ranks higher in the future.
---@param emoji string
function M.record(emoji)
  M._init()
  if emoji_data[emoji] == nil then
    emoji_data[emoji] = { count = 0, timestamps = {} }
  end
  emoji_data[emoji].count = emoji_data[emoji].count + 1
  table.insert(emoji_data[emoji].timestamps, os.time())

  while #emoji_data[emoji].timestamps > MAX_TIMESTAMPS do
    table.remove(emoji_data[emoji].timestamps, 1)
  end

  M._write()
end

local function calculate_score(timestamps)
  local now = os.time()
  local recency_score = 0
  for _, ts in ipairs(timestamps) do
    for _, rank in ipairs(RECENCY_MODIFIER) do
      if (now - ts) / 60 <= rank.age then
        recency_score = recency_score + rank.value
        break
      end
    end
  end
  return recency_score / MAX_TIMESTAMPS
end

---@return table<string, number> scores keyed by emoji character
function M.get_scores()
  M._init()
  local result = {}
  for emoji, data in pairs(emoji_data) do
    result[emoji] = data.count * calculate_score(data.timestamps)
  end
  return result
end

---@param emoji string
---@return number
function M.score_for(emoji)
  return M.get_scores()[emoji] or -1
end

return M
