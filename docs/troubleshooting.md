# Troubleshooting

This page lists known problems and how to fix them. Start with the health check, which finds most problems:

```bash
scripts/check.sh https://vault-mcp.example.com
```

## Setup

### The tunnel container stops right away

**Cause:** `TUNNEL_TOKEN` in `.env` is empty, or it isn't the full token.

**Fix:** Copy only the token from the install command in Cloudflare. It's one long string that starts with `eyJ`. Don't include `cloudflared`, `--token`, quotes, or spaces. Then run `docker compose up -d cloudflared`.

If `TUNNEL_TOKEN` is empty, every `docker compose` command stops with `Set TUNNEL_TOKEN in .env`. This is on purpose.

### A container can't write to its folder

The logs show `EACCES` or `permission denied`.

**Cause:** Docker created the folder because it didn't exist yet. Folders that Docker creates belong to `root`, and the containers run as a regular user.

**Fix:** Give the folders to the container user. Use the `PUID` and `PGID` values from `.env`:

```bash
sudo chown -R 1000:1000 data
```

For the local folder setup on Linux, set `PUID` and `PGID` to the owner of your vault folder instead.

### The server downloads attachments that you turned off

You ran `ob sync-config --file-types ""` to sync notes only, but images and PDFs still download.

**Cause:** In obsidian-headless 0.0.14, an empty `--file-types` list turns **on** all attachment types.

**Fix:** Run the helper script instead. It sets the list directly in the sync settings:

```bash
scripts/notes-only.sh
```

The script stops `ob-sync` while it works and starts it again afterward. Files that already downloaded stay on disk. To remove them, delete them from `VAULT_DIR` while `ob-sync` is stopped, or start again with an empty folder.

> [!CAUTION]
> With two-way sync, a file that you delete in `VAULT_DIR` can be deleted on your other devices too. Before you delete files, set the sync mode to `pull-only`, or ask yourself whether you need those files elsewhere.

### `docker cp` into the MCP server fails

**Cause:** The MCP server's system files are read-only, on purpose.

**Fix:** To add files to the vault, put them in `VAULT_DIR` on the host. The server sees them right away.

## Signing in

### Sign-in fails on your home network

The sign-in works from your phone on mobile data, but fails or loops on your home Wi-Fi.

**Cause:** Your home network answers DNS for your hostname differently from the internet. This happens when your router or local DNS server, such as Pi-hole or AdGuard Home, has its own record for the hostname or its domain. The browser then reaches a local machine instead of Cloudflare, and the sign-in can't finish.

**Fix:** Do one of the following:

- Remove the local DNS record for your MCP hostname, so that it resolves to Cloudflare everywhere.
- Use a hostname that your local DNS doesn't manage.

To check, compare the answers from your local DNS and from a public one. On a computer on your home network, run:

```bash
nslookup vault-mcp.example.com
nslookup vault-mcp.example.com 1.1.1.1
```

Both answers must be Cloudflare addresses.

### The client says that sign-in isn't supported, or can't register

**Cause:** Managed OAuth is off, or the client's redirect URI isn't in the allowed list.

**Fix:** In Cloudflare, open your Access application, and check that **Managed OAuth** is on and that the redirect URI for your client is allowed. See [Turn on Managed OAuth](cloudflare.md#turn-on-managed-oauth). Then check that this command returns JSON with `registration_endpoint`:

```bash
curl -s https://vault-mcp.example.com/.well-known/oauth-authorization-server
```

### You need to change a connector's sign-in settings

**Cause:** Claude doesn't let you edit the sign-in settings of a connector after you add it.

**Fix:** Remove the connector, and then add it again. See [Connect Claude](clients.md#connect-claude).

### The connector worked, but now it fails

**Cause:** The sign-in expired, or you changed the Access application.

**Fix:** In your client, disconnect the server and connect it again. If that doesn't work, run `scripts/check.sh` with your hostname to check the server and Cloudflare.

### Don't add an API key to supergateway

supergateway has an `--apiKey` option. Don't use it with this project. Cloudflare Access handles sign-in. The client sends its Access token, not an API key, so supergateway would reject every request.

## Using the server

### The client sees fewer tools than expected

**Cause:** Read-only mode is on. In read-only mode, the server offers 11 tools instead of 18.

**Fix:** If you want full access, set `MCPVAULT_READ_ONLY=false` in `.env`, run `docker compose up -d vault-mcp`, and reconnect your client. See [Read-only mode](security.md#read-only-mode).

### Writes fail with a read-only error

The client reports `EROFS` or `read-only file system`.

**Cause:** Inbox-only mode is on, and the client tried to write outside the Inbox folder. This is the mode working as intended.

**Fix:** Ask the client to write to the Inbox folder, or turn off Inbox-only mode. See [Inbox-only mode](security.md#inbox-only-mode).

If writes to the Inbox folder also fail, check that the folder exists in the vault. If someone deleted and re-created it, re-create the container with `--force-recreate`.

### A hidden folder still shows up in a client

**Cause:** `MCPVAULT_EXCLUDE` hides folders from search and folder listings only. A client can still open a file there if it knows the path, for example from a link in another note.

**Fix:** To keep notes away from AI apps, keep them out of `VAULT_DIR`. See [What it doesn't protect](security.md#what-it-doesnt-protect).

### Changes don't reach your other devices

This applies only to the Obsidian Sync setup.

**Cause:** The sync mode is still `pull-only`, or the login expired.

**Fix:** Check the sync state:

```bash
docker compose exec ob-sync ob sync-status --path /vault
```

If the mode is `pull-only`, turn on two-way sync. See the last step of the [Obsidian Sync setup](setup.md#obsidian-sync-setup). If the login expired, see [Sign in to Obsidian again](operations.md#sign-in-to-obsidian-again).

## Get more detail

To log every request that passes through the gateway, set `LOG_LEVEL=debug` in `.env`, then run:

```bash
docker compose up -d vault-mcp
docker compose logs -f vault-mcp
```

Set it back to `info` when you finish, because debug logs can contain the text of your notes.
