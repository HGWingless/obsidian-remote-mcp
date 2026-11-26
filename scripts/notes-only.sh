#!/usr/bin/env bash
# Make Obsidian Sync on this server sync notes only (.md, .canvas, .base),
# with no attachments. Works around an obsidian-headless bug where
# `ob sync-config --file-types ""` deletes the setting, which then falls back
# to the default "image, audio, pdf, video". Writing "allowTypes": [] into the
# sync config.json is read as "set, and empty".
#
# Re-run after any obsidian-headless upgrade, and never run
# `ob sync-config --file-types ""` afterwards: it undoes this.
set -euo pipefail
cd "$(dirname "$0")/.."

was_running=$(docker compose ps --status running -q ob-sync)
[ -n "$was_running" ] && docker compose stop ob-sync

docker compose run --rm -T --no-deps --entrypoint node ob-sync - <<'JS'
const fs = require("fs");
const path = require("path");
const base = path.join(process.env.XDG_CONFIG_HOME || path.join(process.env.HOME, ".config"),
                       "obsidian-headless", "sync");
if (!fs.existsSync(base)) { console.error(`No sync config under ${base}. Run ob sync-setup first.`); process.exit(1); }
let n = 0;
for (const id of fs.readdirSync(base)) {
  const file = path.join(base, id, "config.json");
  if (!fs.existsSync(file)) continue;
  const cfg = JSON.parse(fs.readFileSync(file, "utf8"));
  cfg.allowTypes = [];
  fs.writeFileSync(file, JSON.stringify(cfg, null, 2) + "\n");
  console.log(`allowTypes set to [] in ${file}`);
  n++;
}
if (n === 0) { console.error("No vault config.json found."); process.exit(1); }
JS

docker compose run --rm --no-deps ob-sync ob sync-status --path /vault
# Restart continuous sync only if it was running before.
[ -n "$was_running" ] && docker compose up -d ob-sync
exit 0
