-- Load once from ~/.config/hypr/bindings.lua:
-- dofile(os.getenv("HOME") .. "/.config/hypr/wisper-clone.lua")
local wisper = '"' .. os.getenv("HOME") .. '/.local/bin/wisper-clone"'
local function control(action) return hl.dsp.exec_cmd(wisper .. " --control " .. action) end
-- Alt bindings leave applications' Ctrl+Shift shortcuts (Save As, terminal copy)
-- alone. Release binds fire after the key is let go, so a held modifier is
-- unlikely to still be down when the transcript is typed.
hl.bind("ALT + SPACE", control("toggle"), { release = true, description = "Wisper: toggle Record/Polish" })
-- F9 avoids the terminal's Ctrl+Shift+V paste binding.
hl.bind("F9", control("paste-last"), { release = true, description = "Wisper: insert last transcription" })
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
end, { description = "Wisper: push to talk (hold)" })
local function release_ptt()
  if not held_session then return end
  hl.dispatch(hl.dsp.exec_cmd(wisper .. " --control ptt-stop --session " .. held_session))
  held_session = nil
end
hl.bind("F8", release_ptt, { release = true, ignore_mods = true, locked = true })
-- A reload discards held_session, so the new config could never send this
-- recording's release. Stop any push-to-talk recording instead.
hl.on("config.reloaded", function() hl.exec_cmd(wisper .. " --control ptt-stop") end)
hl.bind("ALT + K", control("command-palette"), { description = "Wisper: command palette" })
hl.bind("ALT + N", control("voice-note"), { release = true, description = "Wisper: toggle voice note" })
hl.window_rule({
  name = "wisper-indicator",
  match = { title = "^Wisper Clone Indicator$" },
  float = true, pin = true, no_focus = true,
  move = { "(monitor_w-window_w)/2", "monitor_h-window_h-56" },
})
-- This helper only starts Wisper when Settings > Launch at sign-in is enabled.
hl.on("hyprland.start", function() hl.exec_cmd(wisper .. " --autostart") end)
