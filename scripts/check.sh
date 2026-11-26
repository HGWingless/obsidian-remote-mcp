#!/usr/bin/env bash
# Checks that the stack is healthy.
# Usage: scripts/check.sh [https://vault-mcp.example.com]
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
host="${1:-}"

echo "== containers";      docker compose ps
if docker compose config --services | grep -qx ob-sync; then
  echo "== sync status";   docker compose run --rm --no-deps ob-sync ob sync-status --path /vault
fi
echo "== tunnel";          docker compose logs --tail 200 cloudflared | grep -cE "Registered tunnel connection" | xargs -I{} echo "{} registered connections in recent log (expect 4)"
echo "== local MCP";       docker compose exec -T vault-mcp node --input-type=module - < scripts/probe.mjs

if [ -n "$host" ]; then
  echo "== public /mcp (expect 401 with WWW-Authenticate)"
  curl -si -X POST "$host/mcp" | grep -iE "^HTTP/|^www-authenticate"
  echo "== OAuth metadata (expect a registration_endpoint URL)"
  curl -s "$host/.well-known/oauth-authorization-server" | grep -o '"registration_endpoint":"[^"]*"'
fi
