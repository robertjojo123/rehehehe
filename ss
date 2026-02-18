-- background.lua
-- Fixed-palette looping background player for a MONITOR using text-based .nfv frames.
--
-- Usage:
--   lua background.lua right
--   lua background.lua top
-- If you omit the side, it will try to auto-find a monitor.

local args = {...}
local FILE = "gif_30s.nfv"

-- ===== monitor selection =====
local function getMonitor()
  if args[1] then
    local m = peripheral.wrap(args[1])
    if not m then error("No peripheral on side: "..tostring(args[1])) end
    return m
  end
  local m = peripheral.find("monitor")
  if not m then error("No monitor found. Run: lua background.lua <side>") end
  return m
end

local mon = getMonitor()

-- ===== tune this if needed =====
local TEXT_SCALE = 0.5   -- common for big monitors; try 1.0 / 0.5 / 0.25
local LOOP = true

-- ========= FIXED PALETTE =========
-- Map indices 0..f to RGB values ONCE.
local PALETTE = {
  [0]  = {0.00, 0.00, 0.00},
  [1]  = {0.12, 0.12, 0.12},
  [2]  = {0.22, 0.22, 0.22},
  [3]  = {0.35, 0.35, 0.35},
  [4]  = {0.48, 0.48, 0.48},
  [5]  = {0.65, 0.65, 0.65},
  [6]  = {0.82, 0.82, 0.82},
  [7]  = {1.00, 1.00, 1.00},

  [8]  = {0.30, 0.10, 0.10},
  [9]  = {0.10, 0.25, 0.10},
  [10] = {0.10, 0.15, 0.30},
  [11] = {0.30, 0.30, 0.10},
  [12] = {0.25, 0.10, 0.25},
  [13] = {0.10, 0.25, 0.25},
  [14] = {0.45, 0.30, 0.10},
  [15] = {0.60, 0.60, 0.60},
}
-- ===============================

-- ---------- helpers ----------
local function readNonBlank(h)
  while true do
    local line = h.readLine()
    if line == nil then return nil end
    if line ~= "" then return line end
  end
end

local function waitTimer(id)
  while true do
    local e, tid = os.pullEvent()
    if e == "timer" and tid == id then return end
  end
end

-- ---------- apply palette ONCE ----------
local function applyPalette()
  for i = 0, 15 do
    local c = PALETTE[i]
    local mask = 2 ^ i
    if mon.setPaletteColour then
      mon.setPaletteColour(mask, c[1], c[2], c[3])
    else
      mon.setPaletteColor(mask, c[1], c[2], c[3])
    end
  end
end

local function playOnce()
  local h = fs.open(FILE, "r")
  if not h then error("Can't open "..FILE) end

  local header = h.readLine()
  local w, hgt, fps = header:match("^(%d+)%s+(%d+)%s+(%d+)%s*$")
  w, hgt, fps = tonumber(w), tonumber(hgt), tonumber(fps)
  if not w then h.close(); error("Bad header in "..FILE.." (expected: W H FPS)") end

  -- Configure monitor
  if mon.setTextScale then pcall(function() mon.setTextScale(TEXT_SCALE) end) end
  mon.setCursorBlink(false)
  mon.setBackgroundColor(colors.black)
  mon.clear()

  applyPalette()

  local dt = 1 / fps
  local textRow = string.rep(" ", w)
  local fgRow   = string.rep("0", w)

  local timerId = os.startTimer(0)

  while true do
    local row1 = readNonBlank(h)
    if row1 == nil then break end

    mon.setCursorPos(1, 1)
    mon.blit(textRow, fgRow, row1)

    for y = 2, hgt do
      local row = readNonBlank(h)
      if row == nil then h.close(); return end
      mon.setCursorPos(1, y)
      mon.blit(textRow, fgRow, row)
    end

    waitTimer(timerId)
    timerId = os.startTimer(dt)
  end

  h.close()
end

while true do
  playOnce()
  if not LOOP then break end
end
