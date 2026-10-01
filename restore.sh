#!/usr/bin/env bash
# Restore the LE Audio (LC3) + Bluetooth codec-switcher setup.
#
# Run:  bash restore.sh
#
# What it does:
#   1. Installs ~/.local/bin/bt-codec (the codec switcher)
#   2. Enables the BlueZ ISO-socket kernel feature in /etc/bluetooth/main.conf
#   3. Installs the Omarchy Bluetooth panel with the CODEC dropdown
#   4. Restarts Bluetooth and the shell
#
# Only the panel file and main.conf need root; the script will sudo where needed.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ISO_UUID="6fbaf188-05e0-496a-9885-d6ddfdb4e03e"
BT_CONF="/etc/bluetooth/main.conf"
PANEL="/usr/share/omarchy/shell/plugins/panels/bluetooth/Panel.qml"
STAMP="$(date +%Y%m%d-%H%M%S)"

need_root() {
  if [[ ${EUID} -ne 0 ]]; then echo sudo; else echo ""; fi
}
SUDO="$(need_root)"

echo "==> 1/4  Installing ~/.local/bin/bt-codec"
mkdir -p "$HOME/.local/bin"
install -m 0755 "$HERE/files/bt-codec" "$HOME/.local/bin/bt-codec"

echo "==> 2/4  Enabling BlueZ ISO socket (KernelExperimental)"
if [[ ! -f "$BT_CONF" ]]; then
  echo "    !! $BT_CONF not found, skipping"
else
  $SUDO cp -a "$BT_CONF" "$BT_CONF.bak.$STAMP"
  # Drop any existing uncommented copies, then insert fresh ones under [General]
  $SUDO sed -i -E '/^[[:space:]]*(Experimental|KernelExperimental)[[:space:]]*=/d' "$BT_CONF"
  $SUDO sed -i "1a Experimental = true\nKernelExperimental = $ISO_UUID" "$BT_CONF"
  echo "    Backup: $BT_CONF.bak.$STAMP"
  grep -nE '^\[General\]|^Experimental|^KernelExperimental' "$BT_CONF"
fi

echo "==> 3/4  Installing Omarchy Bluetooth panel (with CODEC dropdown)"
if [[ ! -f "$PANEL" ]]; then
  echo "    !! $PANEL not found, skipping"
else
  $SUDO cp -a "$PANEL" "$PANEL.bak.$STAMP" 2>/dev/null || true
  $SUDO install -m 0644 "$HERE/files/Panel.qml" "$PANEL"
  echo "    Backup: $PANEL.bak.$STAMP"
fi

echo "==> 4/4  Restarting services"
$SUDO systemctl restart bluetooth || true
command -v omarchy-restart-shell >/dev/null 2>&1 && omarchy-restart-shell || true

echo
echo "Done."
echo "Verify with:  bt-codec list"
echo "The FIIO BTR17 must be powered on and paired for LE Audio to connect."
