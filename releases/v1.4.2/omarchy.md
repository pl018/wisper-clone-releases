# Wisper Clone on Omarchy

Wisper Clone 1.4.0 adds a Linux x86_64 AppImage and Hyprland/Wayland
integration. Use the same Deepgram/API settings as Windows, configured afresh
in the Linux app. You do not need Windows, Wine, or a local speech model.

## Install the release

1. Update Omarchy using its normal updater, then install the runtime helpers:

   ```bash
   sudo pacman -S --needed wtype wl-clipboard fuse2 pipewire-alsa
   ```

2. Download the x86_64 `.AppImage`, `install-omarchy.sh`, `wisper-clone.lua`
   (or the legacy `.conf`), and this guide from the release. Run:

   ```bash
   bash install-omarchy.sh ./Wisper.Clone_1.4.2_amd64.AppImage
   ~/.local/bin/wisper-clone
   ```

   Substitute the actual downloaded AppImage filename. The installer copies it
   to `~/.local/lib/wisper-clone/wisper-clone.AppImage`, creates a launcher and
   an application-menu entry, and leaves your Hyprland configuration unchanged.
   Running the installer again upgrades in place: it asks a running instance to
   quit (`--control quit`), which finishes any recording first, and starts the
   new version afterwards. Releases before 1.4.1 do not accept that command; quit
   them from the tray menu first. Updates from Settings replace the installed
   AppImage; leave it in this stable, user-writable location.

3. In Settings, configure Deepgram, choose your recording mode, and confirm
   your system default microphone works using the app's recording controls.

4. Install the matching Hyprland configuration below. Launch Wisper before using
   the shortcuts. Change conflicting keys in your own configuration.

## Hyprland bindings and recording indicator

Current Omarchy uses Lua. Copy `wisper-clone.lua` into `~/.config/hypr/`
and add this line **once** to `~/.config/hypr/bindings.lua`:

```lua
dofile(os.getenv("HOME") .. "/.config/hypr/wisper-clone.lua")
```

For older Hyprland installations using hyprlang, copy `wisper-clone.conf`
into `~/.config/hypr/` and add this line once to `hyprland.conf`:

```ini
source = ~/.config/hypr/wisper-clone.conf
```

Run `hyprctl reload` and check `hyprctl configerrors`. Use the template matching
`hyprctl version`; the legacy template uses `windowrulev2` syntax, which older
Omarchy versions support. Newer versions use the supplied Lua rules.

| Binding | Action |
| --- | --- |
| Hold F8 | Push to talk; release to finish |
| F9, released | Insert the last transcription |
| Alt+Space, released | Toggle Record/Polish |
| Alt+K | Open the command palette |
| Alt+N, released | Toggle a voice note |

The bindings carry descriptions, so they appear in `omarchy menu keybindings`.
None of them are Omarchy defaults. Releases before 1.4.1 used Ctrl+Shift+S,
Ctrl+Shift+K, and Ctrl+Shift+/, which hid application shortcuts such as Save As;
copy the new template over the old one when upgrading.

On the legacy `.conf` template, F8 toggles recording instead of push-to-talk.
The current Lua template attaches session IDs to press/release so a very short
tap cannot start recording after its release.

F8 avoids modifier-only Ctrl+Alt combinations and F9 preserves terminals'
Ctrl+Shift+V paste shortcut. Hyprland combines physically held modifiers with
typed text, so let go of Alt after toggling recording off; the transcript is
typed once processing finishes. Push-to-talk uses no modifier and cannot collide. These Linux bindings are edited in Hyprland;
Windows shortcut settings do not register Wayland shortcuts. The template
floats and pins the recording indicator without a border or keyboard focus. The
cursor-following Polish overlay and Windows selected-text menu are unavailable
on Linux; use the floating indicator and the Text to Speech page instead.

The indicator hides when idle. It appears while you record and while Wisper
processes the recording, and it appears while the main window is focused. Its
idle pill is as large as the recording one and names the mode a click starts.
Moving the pointer within 50 px of the pill keeps it visible. Press there or on
the pill and drag it where you want it; Wisper remembers the spot. Settings >
Advanced > Reset position moves it back to the bottom center. While it is
visible, that margin catches clicks meant for the window underneath.

The template uses `no_initial_focus` rather than `no_focus`: `no_focus` also
stops mouse input, so the pill could not be hovered, clicked, or dragged. The
window refuses keyboard focus itself, so dictated text still goes to the app
you are typing in. The AppImage runs under
XWayland and places the indicator itself. A native Wayland build (for example
`pnpm tauri dev`) cannot, so the template's second rule places it at the bottom
center and a dragged position lasts only until it hides.

Launch at sign-in stays **off by default**. The template's startup helper honors
Settings > General > Launch Wisper Clone at sign-in. Enable it, then sign out and
back in. It checks the Tauri plugin's `~/.config/autostart/Wisper Clone.desktop` entry,
so it also works when Hyprland does not run XDG autostart entries itself. If the
app was already running when you reload the configuration, it is not restarted.
Update checks also remain opt-in.

## Control commands

```bash
~/.local/bin/wisper-clone --control toggle
~/.local/bin/wisper-clone --control start
~/.local/bin/wisper-clone --control stop
~/.local/bin/wisper-clone --control ptt-start
~/.local/bin/wisper-clone --control ptt-stop
~/.local/bin/wisper-clone --control paste-last
~/.local/bin/wisper-clone --control voice-note
~/.local/bin/wisper-clone --control show
~/.local/bin/wisper-clone --control quit
```

Commands contact the running app through a socket under
`$XDG_RUNTIME_DIR/wisper-clone/`, restricted to your user. Recording and paste
commands do not raise the main window. Start/stop commands are safe to repeat;
PTT-stop cannot stop a different recording mode. Keep the same logged-in desktop
session and runtime directory for the app and commands. Commands fail clearly
if the app has not started or an action fails.

`quit` stops any recording through its normal path, saves it, and returns once
the app has exited. Use it in scripts instead of `kill`: killing the AppImage
runtime unmounts the image under the running app, which then crashes (SIGBUS).
Closing the main window only hides it to the tray.

Automatic typing uses `wtype` to deliver Unicode through stdin without shell
interpolation. Paste-last also puts a recovery copy on the Wayland clipboard.
Control characters are removed, matching the existing Windows delivery policy;
text is inserted without an Enter keystroke. The target is the currently focused
application when delivery occurs. Keep focus in the intended text field and
release shortcut modifiers. GNOME/KDE and Linux X11 typing are not supported by
this Hyprland integration.

## Build from source

Install Tauri's Arch dependencies and audio/input development libraries:

```bash
sudo pacman -S --needed base-devel webkit2gtk-4.1 curl wget file openssl \
  appmenu-gtk-module libappindicator-gtk3 librsvg xdotool alsa-lib \
  libx11 libxtst libxi wtype wl-clipboard fuse2 pipewire-alsa gst-plugins-base gst-plugins-good
```

Use Linux-native Node matching `package.json` (22.22.2+, 24.15.0+, or 26+),
pnpm 9.15.9, and rustup with Rust 1.95.0 (pinned in `rust-toolchain.toml`).
Do not reuse Windows `node_modules` or Windows Rust targets.

```bash
pnpm install --frozen-lockfile
pnpm check
pnpm tauri dev
# Local packaging without the production signing key:
GSTREAMER_PLUGINS_DIR=$(bash scripts/prepare-linux-media.sh)
export GSTREAMER_PLUGINS_DIR
pnpm tauri build --bundles appimage --config '{"bundle":{"createUpdaterArtifacts":false}}'
```

On Arch, add `NO_STRIP=true` to the build command. The `strip` bundled with
linuxdeploy cannot read Arch's `.relr.dyn` sections and fails the bundle.

The packaging helper selects the audio plugins used by the app so unrelated
video codecs do not exceed the public updater mirror's 100 MiB file limit.
Production AppImages are signed by the release workflow. The Windows and Linux
jobs run serially and produce a combined updater manifest. Release tags must
reference a commit already merged into the default branch (`master` in this
repository). CI checks both platforms before merge.

## Validation and troubleshooting

- Verify the indicator stays floating and the editor retains focus when you
  toggle recording. Missing window rules can cause Hyprland to tile the pill.
  A frame around the pill means a template from before 1.4.2 is still loaded.
- Test immediate speech, very short F8 presses, long speech, repeated presses,
  Unicode, and paste-last in your browser, editor, and terminal.
- Select the microphone in Omarchy's audio controls before opening Wisper.
  Test TTS playback and microphone recovery after unplug/replug and suspend.
- If `wtype` fails, run it from a terminal in the same Wayland session. Install
  both helpers; paste-last keeps text on the clipboard if insertion fails.
  `wtype` requires compositor support for the virtual keyboard protocol.
- If text does not appear, search the log for `auto_type.`: `delivered` means
  `wtype` succeeded and the text went to the window focused at that moment,
  `skipped` names the setting that blocked it, and `failed` includes the error.
- Blank windows with `Could not create default EGL display: EGL_BAD_PARAMETER`
  in the log come from the AppImage's bundled libwayland. Since 1.4.1 the app
  restarts itself once with the system `libwayland-client` and `libwayland-egl`
  preloaded. Remove any `LD_PRELOAD` workaround added to the launcher by hand;
  the installer rewrites the launcher anyway.
- If a release event is missed during a lock or suspend, run `--control stop`
  or use the app's stop control before starting another recording.
- Linux data: `~/.local/share/com.wisperclone.app/` (or `$XDG_DATA_HOME`).
  Logs: `~/.local/share/wisper-clone/logs/`. Windows settings/history are not
  migrated automatically. Configure API credentials locally.

Native Linux compilation and automated tests do not prove microphone quality,
focus behavior, or suspend/resume on every Omarchy machine. Run the above
checks in the actual Hyprland session before relying on it for daily dictation.

References: [Tauri prerequisites](https://v2.tauri.app/start/prerequisites/),
[Hyprland bindings](https://wiki.hypr.land/configuring/core/binds/),
[Omarchy dotfiles](https://omarchy.org/manual/dotfiles/).
