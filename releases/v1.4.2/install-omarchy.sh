#!/usr/bin/env bash
set -euo pipefail
if [[ $# != 1 || ! -f "$1" ]]; then
  echo 'Usage: bash install-omarchy.sh /path/to/Wisper.Clone_VERSION_amd64.AppImage' >&2
  exit 2
fi
if [[ $(uname -m) != x86_64 ]]; then
  echo 'This release contains an x86_64 AppImage.' >&2
  exit 1
fi
for helper in wtype wl-copy; do
  command -v "$helper" >/dev/null || { echo "Install dependencies first: sudo pacman -S --needed wtype wl-clipboard fuse2 pipewire-alsa" >&2; exit 1; }
done
app_dir="$HOME/.local/lib/wisper-clone"
bin_dir="$HOME/.local/bin"
apps_dir="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
mkdir -p "$app_dir" "$bin_dir" "$apps_dir"
# Install through a temporary file so a failed copy leaves the old version intact.
install -m 755 -- "$1" "$app_dir/wisper-clone.AppImage.new"
# Ask a running instance to quit so it finishes any recording and exits cleanly.
# Killing the AppImage runtime instead unmounts the image under the app (SIGBUS).
# Quit returns once the app has exited; releases before 1.4.1 reject it.
was_running=0
if quit_error=$("$app_dir/wisper-clone.AppImage.new" --control quit 2>&1); then
  was_running=1
elif [[ $quit_error != *'Start Wisper Clone first'* ]]; then
  printf 'Could not stop the running Wisper Clone: %s\n' "$quit_error" >&2
  echo 'Quit it from its tray menu, then start the new version.' >&2
fi
mv -f -- "$app_dir/wisper-clone.AppImage.new" "$app_dir/wisper-clone.AppImage"
cat > "$bin_dir/wisper-clone" <<'LAUNCHER'
#!/usr/bin/env bash
set -euo pipefail
# Hyprland does not necessarily process XDG autostart entries itself. Honor the
# Tauri autostart plugin's opt-in registration when called by the supplied config.
if [[ ${1:-} == --autostart ]]; then
  [[ -f "$HOME/.config/autostart/Wisper Clone.desktop" ]] || exit 0
  shift
fi
exec "$HOME/.local/lib/wisper-clone/wisper-clone.AppImage" "$@"
LAUNCHER
chmod 755 "$bin_dir/wisper-clone"
# Desktop Entry Exec quoting escapes have their own rules (not shell quoting).
launcher=${bin_dir//\\/\\\\}/wisper-clone
launcher=${launcher//\"/\\\"}
launcher=${launcher//\$/\\\$}
launcher=${launcher//\`/\\\`}
launcher=${launcher//%/%%}
cat > "$apps_dir/com.wisperclone.app.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Wisper Clone
Comment=Speech to text and voice notes
Exec="$launcher"
Terminal=false
Categories=Utility;Audio;
StartupWMClass=app
DESKTOP
command -v update-desktop-database >/dev/null && update-desktop-database "$apps_dir" || true
if (( was_running )); then
  setsid -f "$bin_dir/wisper-clone" >/dev/null 2>&1 </dev/null
  echo 'Restarted Wisper Clone with the new version.'
else
  printf 'Installed Wisper Clone. Start with: %s/wisper-clone\n' "$bin_dir"
fi
echo 'Install the matching wisper-clone.lua or wisper-clone.conf bindings as described in omarchy.md.'
echo 'Launch at sign-in and update checks remain opt-in in Settings.'
