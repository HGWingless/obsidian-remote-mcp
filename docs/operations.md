# Run and maintain

This page covers what to do after setup: keep the server running, check on it, update it, and remove it.

## Start automatically

You don't need to start the containers by hand each time. After you run `docker compose up -d` once, Docker restarts them on its own after a crash or a reboot. Each container has the restart policy `unless-stopped`.

For this to work after a reboot, Docker itself must start when the machine starts:

| Platform | What to do |
|---|---|
| Linux | Run `sudo systemctl enable docker.service containerd.service`. Most distributions do this when you install Docker. |
| Docker Desktop (Mac or Windows) | In **Settings > General**, turn on **Start Docker Desktop when you sign in to your computer**. |
| OrbStack (Mac) | In **Settings > General**, turn on **Start at login**. |
| Synology | Nothing. Container Manager starts with DSM. |

> [!NOTE]
> Docker Desktop and OrbStack start only after you sign in to your computer. If your Mac or PC restarts and nobody signs in, the server stays off. For a server that must always be on, use a Linux machine, a cloud server, or a NAS.

> [!IMPORTANT]
> `unless-stopped` means that a container you stop on purpose stays stopped, even after a reboot. To start it again, run `docker compose up -d`.

Also keep the machine awake. A computer that sleeps takes the server offline.

## Stop access in an emergency

If you think someone else has access, or a client is changing notes it shouldn't, stop the MCP server:

```bash
docker compose stop vault-mcp
```

This cuts off every MCP client at once. Obsidian Sync, if you use it, keeps running. The server stays stopped after a reboot until you start it again.

Then check and fix the cause:

1. In Cloudflare, open your Access application, and check that its policy allows only your email address.
1. In the Zero Trust logs for Access, review recent sign-ins.
1. If you think your tunnel token leaked, [rotate the tunnel token](#rotate-the-tunnel-token).
1. If a client changed or deleted notes, restore them. With Obsidian Sync, use version history in the Obsidian app. Otherwise, use your backups.
1. Start the server again:

   ```bash
   docker compose up -d vault-mcp
   ```

To stop everything, including sync and the tunnel, run `docker compose stop`.

## Check health and logs

To check everything at once, run:

```bash
scripts/check.sh https://vault-mcp.example.com
```

To see the containers and their health:

```bash
docker compose ps
```

To read the logs of one container, such as `vault-mcp`:

```bash
docker compose logs --tail 50 vault-mcp
```

To follow the logs as they happen, add `-f`. Press Ctrl+C to stop.

For the Obsidian Sync setup, to see the sync state:

```bash
docker compose exec ob-sync ob sync-status --path /vault
```

## Update

The versions of each part are set in `.env`. This keeps updates under your control.

1. Check for new releases of the parts that you want to update:
   - [MCPVault](https://github.com/bitbonsai/mcpvault/releases)
   - [supergateway](https://github.com/supercorp-ai/supergateway/releases)
   - [cloudflared](https://github.com/cloudflare/cloudflared/releases)
   - [obsidian-headless](https://www.npmjs.com/package/obsidian-headless?activeTab=versions)
1. In `.env`, change the version numbers.
1. Rebuild the images and pull the new cloudflared image:

   ```bash
   docker compose build --pull
   docker compose pull cloudflared
   ```

1. Restart with the new versions:

   ```bash
   docker compose up -d
   ```

1. Run `scripts/check.sh` to confirm that everything works.

To get the latest repository files, run `git pull` before you rebuild. If `.env.example` changed, compare it with your `.env`.

> [!TIP]
> To go back to an older version, set the old version number in `.env`, then rebuild and restart.

## Rotate the tunnel token

Anyone with your tunnel token can run your tunnel. Rotate it if you think it leaked.

1. In the Cloudflare dashboard, open your tunnel, and select **Rotate token** (some dashboards call it **Refresh token**).
1. Copy the new token from the install command. It starts with `eyJ`.
1. Replace `TUNNEL_TOKEN` in `.env`. You can use the command in [Create the tunnel](cloudflare.md#create-the-tunnel).
1. Restart the tunnel:

   ```bash
   docker compose up -d cloudflared
   ```

For details, see [Tunnel tokens](https://developers.cloudflare.com/tunnel/reference/tunnel-tokens/) in the Cloudflare documentation.

## Sign in to Obsidian again

This applies only to the Obsidian Sync setup. If sync stops because the login expired, or you changed your Obsidian password:

```bash
docker compose stop ob-sync
docker compose run --rm ob-sync ob login
docker compose up -d ob-sync
```

## Uninstall

1. For the Obsidian Sync setup only, disconnect the vault and sign out of Obsidian:

   ```bash
   docker compose stop ob-sync
   docker compose run --rm ob-sync ob sync-unlink --path /vault
   docker compose run --rm ob-sync ob logout
   ```

1. Stop and remove the containers, the network, and the built images:

   ```bash
   docker compose down --rmi local
   ```

1. In Cloudflare, delete the tunnel, the Access application, and the DNS record for your hostname.
1. In your MCP client, remove the connector.
1. For the Obsidian Sync setup, delete `OB_HOME_DIR`. By default, it's `data/ob-home`.

> [!CAUTION]
> `docker compose down` doesn't delete your vault. In the local folder setup, `VAULT_DIR` is your real vault. Don't delete it. In the Obsidian Sync setup, `VAULT_DIR` is a copy. You can delete it after you confirm that your other devices have all your notes.
