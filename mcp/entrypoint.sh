#!/bin/sh
# Builds the MCPVault command line from environment variables and hands it to
# supergateway. supergateway runs the --stdio string through /bin/sh, so every
# vault-relative path is single-quoted here to survive spaces.
#
#   MCPVAULT_EXCLUDE    comma-separated folders hidden from search and listing
#                       (NOT an access control: direct reads still work)
#   MCPVAULT_READ_ONLY  "true" to expose read tools only
#   SESSION_TIMEOUT_MS  idle MCP session lifetime (default 1 hour)
#   LOG_LEVEL           supergateway log level: debug, info or none
set -eu

quote() {
  # Wrap in single quotes; turn each embedded ' into '"'"'
  printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\"'\"'/g")"
}

cmd="mcpvault /vault"

if [ -n "${MCPVAULT_EXCLUDE:-}" ]; then
  old_ifs=$IFS
  IFS=','
  for folder in $MCPVAULT_EXCLUDE; do
    folder=$(printf '%s' "$folder" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    [ -n "$folder" ] && cmd="$cmd --exclude $(quote "$folder")"
  done
  IFS=$old_ifs
fi

case "${MCPVAULT_READ_ONLY:-false}" in
  true|TRUE|1|yes) cmd="$cmd --read-only" ;;
  false|FALSE|0|no|"") ;;
  *) echo "MCPVAULT_READ_ONLY must be true or false" >&2; exit 64 ;;
esac

exec supergateway \
  --stdio "$cmd" \
  --outputTransport streamableHttp \
  --stateful \
  --sessionTimeout "${SESSION_TIMEOUT_MS:-3600000}" \
  --port 8000 \
  --healthEndpoint /healthz \
  --logLevel "${LOG_LEVEL:-info}"
