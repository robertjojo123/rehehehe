-- background_textpal.lua
-- Plays TEXT NFV with per-frame palette + hex bg lines (0-9a-f), on a monitor.
--
-- Usage:
--   lua background_textpal.lua right
-- File expected: "vid_30s.nfv" in local filesystem

local args = {...}
local FILE = "vid_30s.nfv"
local SIDE = args[1]

local function getMonitor()
  if SIDE then
    local m = peripheral.wrap(SIDE)
    if not m then error("No peripheral on side: "..tostring(SIDE)) end
    return m
  end
  local m = peripheral.find("monitor")
  if not m then error("No monitor found. Run: lua background_textpal.lua <side>") end
  return m
end

local mon = getMonitor()

local TEXT_SCALE = 0.5
local LOOP = true

local HEX_OK = "0123456789abcdef"

local function waitTimer(id)
  while true do
    local e, tid = os.pullEvent()
    if e == "timer" and tid == id then return end
  end
end

local function readNonBlank(h)
  while true do
    local line = h.readLine()
    if line == nil then return nil end
    if line ~= "" then return line end
  end
end

local function setPaletteEntry(i, r, g, b)
  local mask = 2^i
  local rr, gg, bb = r/255, g/255, b/255
  if mon.setPaletteColour then
    mon.setPaletteColour(mask, rr, gg, bb)
  else
    mon.setPaletteColor(mask, rr, gg, bb)
  end
end

local function applyPaletteBlock(h)
  -- expects 16 lines "r g b"
  for i=0,15 do
    local line = readNonBlank(h)
    if not line then error("EOF while reading palette") end
    local r, g, b = line:match("^(%d+)%s+(%d+)%s+(%d+)%s*$")
    if not r then error("Bad palette line: "..tostring(line)) end
    setPaletteEntry(i, tonumber(r), tonumber(g), tonumber(b))
  end
end

local function playOnce()
  local h = fs.open(FILE, "r")
  if not h then error("Can't open "..FILE) end

  local header = h.readLine()
  local w, hh, fps = header:match("^(%d+)%s+(%d+)%s+(%d+)%s*$")
  w, hh, fps = tonumber(w), tonumber(hh), tonumber(fps)
  if not w then h.close(); error("Bad header. Expected: W H FPS") end

  if mon.setTextScale then pcall(function() mon.setTextScale(TEXT_SCALE) end) end
  mon.setCursorBlink(false)
  mon.setBackgroundColor(colors.black)
  mon.clear()

  local dt = 1 / fps
  local textRow = string.rep(" ", w)
  local fgRow   = string.rep("0", w)

  local timerId = os.startTimer(0)

  while true do
    local marker = readNonBlank(h)
    if marker == nil then break end

    if marker ~= "P" then
      -- If file has stray blanks, we skip; otherwise this indicates corruption
      error("Expected 'P' palette marker, got: "..tostring(marker))
    end

    -- read palette (16 lines)
    applyPaletteBlock(h)

    -- read & draw frame (H lines)
    for y=1,hh do
      local row = readNonBlank(h)
      if not row then h.close(); return end
      -- Basic validation
      if #row ~= w then error(("Bad row length at y=%d: expected %d got %d"):format(y, w, #row)) end
      if row:find("[^0-9a-f]") then error("Row has non-hex characters") end

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
