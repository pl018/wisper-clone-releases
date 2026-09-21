-- Load once from ~/.config/hypr/bindings.lua:
-- dofile(os.getenv("HOME") .. "/.config/hypr/wisper-clone.lua")
local wisper = '"' .. os.getenv("HOME") .. '/.local/bin/wisper-clone"'
local function control(action) return hl.dsp.exec_cmd(wisper .. " --control " .. action) end
hl.bind("CTRL + SHIFT + S", control("toggle"), { release = true })
-- F9 avoids the terminal's Ctrl+Shift+V paste binding.
hl.bind("F9", control("paste-last"), { release = true })
-- A non-modifier key avoids triggering Ctrl+Alt system shortcuts while dictating.
-- Tokens are captured synchronously in compositor event order, before either
-- AppImage process is scheduled. Late starts are ignored after their release.
local epoch = tostring(os.time()) .. "-" .. tostring(math.random(1, 2147483647))
local sequence, held_session = 0, nil
hl.bind("F8", function()
  if held_session then return end
  sequence = sequence + 1
  held_session = epoch .. "-" .. tostring(sequence)
  hl.dispatch(hl.dsp.exec_cmd(wisper .. " --control ptt-start --session " .. held_session))
end)
local function release_ptt()
  if not held_session then return end
  hl.dispatch(hl.dsp.exec_cmd(wisper .. " --control ptt-stop --session " .. held_session))
  held_session = nil
end
hl.bind("F8", release_ptt, { release = true, ignore_mods = true, locked = true })
hl.on("config.unload", release_ptt)
hl.bind("CTRL + SHIFT + K", control("command-palette"))
hl.bind("CTRL + SHIFT + slash", control("voice-note"), { release = true })
hl.window_rule({
  name = "wisper-indicator",
  match = { title = "^Wisper Clone Indicator$" },
  float = true, pin = true, no_focus = true,
  move = { "(monitor_w-window_w)/2", "monitor_h-window_h-56" },
})
-- This helper only starts Wisper when Settings > Launch at sign-in is enabled.
hl.on("hyprland.start", function() hl.exec_cmd(wisper .. " --autostart") end)
