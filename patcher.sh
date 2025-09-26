#!/bin/bash

SUCCESS=0

logged_in_user=$(logname 2>/dev/null || whoami)
logged_in_home=$(eval echo "~${logged_in_user}")

PLUGIN_DIR="$logged_in_home/homebrew/plugins/SDH-GameThemeMusic"
BIN_DIR="${PLUGIN_DIR}/bin"
MAIN_PY_PATH="${PLUGIN_DIR}/main.py"
YTDLP_PATH="${BIN_DIR}/yt-dlp"

MAIN_PY_URL="https://raw.githubusercontent.com/moraroy/SDH-GameThemeMusic/main/main.py"
YTDLP_RELEASE_URL="https://github.com/yt-dlp/yt-dlp/releases/latest"

FINAL_URL=$(curl -s -L -o /dev/null -w "%{url_effective}" "$YTDLP_RELEASE_URL")
VERSION_NAME=$(basename "$FINAL_URL")
YTDLP_URL="https://github.com/yt-dlp/yt-dlp/releases/download/$VERSION_NAME/yt-dlp"

password=$(zenity --password --title="Authentication Required")

if [ -z "$password" ]; then
  zenity --notification --text="Authentication cancelled." --timeout=2
  exit 1
fi

ASKPASS_SCRIPT=$(mktemp)
chmod 700 "$ASKPASS_SCRIPT"
cat > "$ASKPASS_SCRIPT" <<EOF
#!/bin/bash
echo "$password"
EOF
export SUDO_ASKPASS="$ASKPASS_SCRIPT"

sudo -A -k -v >/dev/null 2>&1
if [ $? -ne 0 ]; then
  zenity --error --text="Incorrect password or no sudo access."
  rm -f "$ASKPASS_SCRIPT"
  exit 1
fi

curl -fsSL "$MAIN_PY_URL" -o "/tmp/main.py"
if [ $? -ne 0 ]; then
  zenity --error --text="Failed to download main.py"
  rm -f "$ASKPASS_SCRIPT"
  exit 1
fi

curl -fsSL "$YTDLP_URL" -o "/tmp/yt-dlp"
if [ $? -ne 0 ]; then
  zenity --error --text="Failed to download yt-dlp binary"
  rm -f "$ASKPASS_SCRIPT"
  exit 1
fi

run_sudo() {
  sudo -A "$@"
  if [ $? -ne 0 ]; then
    zenity --error --text="Failed: $*"
    rm -f "$ASKPASS_SCRIPT"
    exit 1
  fi
}

run_sudo mkdir -p "$BIN_DIR"
run_sudo chmod u+w "$PLUGIN_DIR" "$BIN_DIR"
run_sudo rm -f "$MAIN_PY_PATH" "$YTDLP_PATH"
run_sudo mv /tmp/main.py "$MAIN_PY_PATH"
run_sudo mv /tmp/yt-dlp "$YTDLP_PATH"
run_sudo chmod 644 "$MAIN_PY_PATH"
run_sudo chmod 755 "$YTDLP_PATH"
run_sudo chmod u-w "$PLUGIN_DIR" "$BIN_DIR"

SUCCESS=1

rm -f "$ASKPASS_SCRIPT"

if [ "$SUCCESS" -eq 1 ]; then
  zenity --notification --text="Patch successful. Switch to Gaming Mode when ready. You may need to reload the plugin!" --timeout=4
  exit 0
else
  exit 1
fi

