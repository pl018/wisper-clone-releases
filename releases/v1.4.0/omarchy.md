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
   bash install-omarchy.sh ./Wisper.Clone_1.4.0_amd64.AppImage
   ~/.local/bin/wisper-clone
   ```

   Substitute the actual downloaded AppImage filename. The installer copies it
   to `~/.local/lib/wisper-clone/wisper-clone.AppImage`, creates a launcher and
   an application-menu entry, and leaves your Hyprland configuration unchanged.
   Quit the old instance before installing another version. Updates from Settings
   replace the installed AppImage; leave it in this stable, user-writable location.

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
| Ctrl+Shift+S, released | Toggle Record/Polish |
| Hold F8 | Push to talk; release to finish |
| F9, released | Insert the last transcription |
| Ctrl+Shift+K | Open the command palette |
| Ctrl+Shift+/ | Toggle a voice note |

On the legacy `.conf` template, F8 toggles recording instead of push-to-talk.
The current Lua template attaches session IDs to press/release so a very short
tap cannot start recording after its release.

F8 avoids modifier-only Ctrl+Alt combinations and F9 preserves terminals'
Ctrl+Shift+V paste shortcut. These Linux bindings are edited in Hyprland;
Windows shortcut settings do not register Wayland shortcuts. The template
floats and pins the recording indicator without taking keyboard focus. The
cursor-following Polish overlay and Windows selected-text menu are unavailable
on Linux; use the fixed indicator and the Text to Speech page instead.

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
```

Commands contact the running app through a socket under
`$XDG_RUNTIME_DIR/wisper-clone/`, restricted to your user. Recording and paste
commands do not raise the main window. Start/stop commands are safe to repeat;
PTT-stop cannot stop a different recording mode. Keep the same logged-in desktop
session and runtime directory for the app and commands. Commands fail clearly
if the app has not started or an action fails.

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

The packaging helper selects the audio plugins used by the app so unrelated
video codecs do not exceed the public updater mirror's 100 MiB file limit.
Production AppImages are signed by the release workflow. The Windows and Linux
jobs run serially and produce a combined updater manifest. Release tags must
reference a commit already merged into the default branch (`master` in this
repository). CI checks both platforms before merge.

## Validation and troubleshooting

- Verify the indicator stays floating and the editor retains focus when you
  toggle recording. Missing window rules can cause Hyprland to tile the pill.
- Test immediate speech, very short F8 presses, long speech, repeated presses,
  Unicode, and paste-last in your browser, editor, and terminal.
- Select the microphone in Omarchy's audio controls before opening Wisper.
  Test TTS playback and microphone recovery after unplug/replug and suspend.
- If `wtype` fails, run it from a terminal in the same Wayland session. Install
  both helpers; paste-last keeps text on the clipboard if insertion fails.
  `wtype` requires compositor support for the virtual keyboard protocol.
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
