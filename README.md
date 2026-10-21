# Omarchy — Bluetooth LE Audio (LC3) + codec switcher

Backup of the customizations that enable **Bluetooth LE Audio (LC3)** on this
machine and add a **codec switcher to the Omarchy Bluetooth panel**.

Restore everything with:

```bash
bash restore.sh
```

## What's here

| File | Installs to | Purpose |
|------|-------------|---------|
| `files/bt-codec` | `~/.local/bin/bt-codec` | CLI to switch Bluetooth codecs |
| `files/Panel.qml` | `/usr/share/omarchy/shell/plugins/panels/bluetooth/Panel.qml` | Omarchy Bluetooth panel + **CODEC** dropdown |
| `restore.sh` | — | Applies all of the above |

## What the setup does

1. **Enables the BlueZ ISO socket** (LE Audio transport) by setting, in
   `/etc/bluetooth/main.conf` under `[General]`:

   ```ini
   Experimental = true
   KernelExperimental = 6fbaf188-05e0-496a-9885-d6ddfdb4e03e
   ```

   The kernel already contains the ISO-socket code (`CONFIG_BT_LE=y`); this only
   flips BlueZ's runtime gate — **no kernel rebuild is required**.

2. **Adds a CODEC dropdown** to the Bluetooth panel, shown under **CONNECTED**
   whenever the FIIO BTR17 is connected. Options:
   `LC3 (LE Audio)` · `LDAC` · `aptX HD` · `aptX` · `AAC` · `SBC`.

## CLI usage

The headset address comes from the environment, so no personal device
identifier is baked into the script:

```bash
export BT_CODEC_ADDR=AA:BB:CC:DD:EE:FF   # the FiiO BTR17
```

```bash
bt-codec list        # show codecs + current profile
bt-codec current     # print the active codec id (lc3|ldac|aptx_hd|aptx|aac|sbc)
bt-codec set lc3     # LE Audio — LC3, mic + output (retries the LE link)
bt-codec set ldac    # A2DP LDAC
bt-codec set aptx_hd # A2DP aptX HD
bt-codec set aac     # A2DP AAC
bt-codec set sbc     # A2DP SBC
bt-codec auto        # restore automatic codec selection
```

## Notes / caveats

- **Package updates:** `omarchy` updates overwrite
  `/usr/share/omarchy/shell/plugins/panels/bluetooth/Panel.qml`.
  Re-run `bash restore.sh` afterwards.
- **Shell restart:** the Omarchy shell runs with `QS_DISABLE_FILE_WATCHER=1`, so
  panel changes require `omarchy-restart-shell` (the restore script runs it).
- **Device:** the FIIO BTR17 must be powered on and paired. The LE link
  occasionally needs a second connect attempt; `bt-codec set lc3` retries
  automatically.
- **Rollback:** `restore.sh` writes timestamped `.bak.<stamp>` files next to
  each file it replaces. Copy one back to undo.

## Verified environment

- Kernel `7.2.5-3-omarchy` (MediaTek BT 5.3 adapter)
- BlueZ 5.87, PipeWire 1.6.8, WirePlumber 0.5.17
- Omarchy shell (quickshell)
