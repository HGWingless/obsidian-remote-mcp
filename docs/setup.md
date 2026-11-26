# Set up the server

This page shows you how to install obsidian-remote-mcp on the machine that runs Docker. When you finish, you set up Cloudflare and connect your MCP client.

## Before you begin

- Install Docker and Docker Compose on the machine. See [Where it runs](platforms.md) for your platform.
- Decide which setup you want. If you're not sure, see [Choose a setup](../README.md#choose-a-setup).
  - **Local folder:** the vault is already on this machine.
  - **Obsidian Sync:** this machine keeps its own copy of your vault with Obsidian Sync.
- Have a domain name that uses Cloudflare DNS. You need it in the Cloudflare steps.

> [!TIP]
> The commands on this page are for a Linux or macOS terminal. On Windows, run them in a WSL terminal, or see the PowerShell notes in each step.

## Step 1: Get the files

1. Download the repository and go to its folder:

   ```bash
   git clone https://github.com/OWNER/obsidian-remote-mcp.git
   cd obsidian-remote-mcp
   ```

   Replace `OWNER` with the GitHub account that hosts the repository.

1. Create your settings file from the example:

   ```bash
   cp .env.example .env
   chmod 600 .env
   ```

   <details>
   <summary>Windows PowerShell</summary>

   ```powershell
   Copy-Item .env.example .env
   ```

   </details>

1. Open `.env` in a text editor. You fill in the values in the next steps.

## Step 2: Connect your vault

Follow the steps for your setup.

### Local folder setup

1. In `.env`, leave `COMPOSE_PROFILES` empty.
1. Set `VAULT_DIR` to the full path of your vault folder. This is the folder that contains the `.obsidian` folder.

   | Platform | Example |
   |---|---|
   | Linux | `VAULT_DIR=/home/alex/Documents/MyVault` |
   | macOS | `VAULT_DIR=/Users/alex/Documents/MyVault` |
   | Windows | `VAULT_DIR=C:/Users/alex/Documents/MyVault` (use forward slashes) |

1. On Linux, set `PUID` and `PGID` to the owner of the vault folder. To find them, run `id -u` and `id -g` as that user. On macOS and Windows, keep the defaults.
1. Build the images:

   ```bash
   docker compose build
   ```

1. Continue to [Step 3](#step-3-set-up-cloudflare).

> [!NOTE]
> The Obsidian app can stay open while the server runs. Obsidian notices changes that the server makes and shows them. If you and an AI app edit the same note at the same moment, one change can overwrite the other.

### Obsidian Sync setup

In this setup, the `ob-sync` container signs in to your Obsidian account and keeps a copy of your vault on this machine. It shows up as its own device in Obsidian Sync.

1. In `.env`, set `COMPOSE_PROFILES=obsidian-sync`.
1. Keep the default folders, or set `VAULT_DIR` and `OB_HOME_DIR` to empty folders of your choice.
1. Create the folders and give them to the container user. If you create them yourself, Docker doesn't create them as `root`, which the containers can't write to.

   ```bash
   mkdir -p data/vault data/ob-home
   sudo chown -R 1000:1000 data
   ```

   If you changed `PUID` or `PGID`, use those numbers instead of `1000:1000`.

1. Build the images:

   ```bash
   docker compose build
   ```

1. Sign in to your Obsidian account. Enter your email, password, and two-factor code when asked.

   ```bash
   docker compose run --rm ob-sync ob login
   ```

1. List your vaults in Obsidian Sync:

   ```bash
   docker compose run --rm ob-sync ob sync-list-remote
   ```

1. Connect this machine to your vault:

   ```bash
   docker compose run --rm ob-sync \
     ob sync-setup --vault "VAULT_NAME" --path /vault --device-name DEVICE_NAME
   ```

   Replace the following:

   - `VAULT_NAME`: the name of your vault, from the previous step.
   - `DEVICE_NAME`: a name for this machine, such as `mcp-server`. It appears in Obsidian Sync version history.

   If your vault uses end-to-end encryption, the command asks for the encryption password.

   > [!CAUTION]
   > Don't add `--password` to this command. A password on the command line is saved in your shell history.

1. Set the sync options. This command downloads only, never syncs Obsidian settings, and merges conflicting edits:

   ```bash
   docker compose run --rm ob-sync ob sync-config --path /vault \
     --mode pull-only --conflict-strategy merge --configs ""
   ```

   To keep folders off this machine, add `--excluded-folders "FOLDER_1,FOLDER_2"`.

1. Optional: sync notes only, without images, PDFs, audio, or video. This keeps the copy small.

   ```bash
   scripts/notes-only.sh
   ```

   > [!WARNING]
   > Don't use `ob sync-config --file-types ""` for this. It turns on all attachment types instead. For details, see [Troubleshooting](troubleshooting.md#the-server-downloads-attachments-that-you-turned-off).

1. Download your vault once, then check the result:

   ```bash
   docker compose run --rm ob-sync ob sync --path /vault
   docker compose run --rm ob-sync ob sync-status --path /vault
   ```

   Look in your `VAULT_DIR` folder to confirm that your notes arrived.

1. Turn on two-way sync, so that changes from your MCP client reach your other devices:

   ```bash
   docker compose run --rm ob-sync ob sync-config --path /vault --mode bidirectional
   ```

## Step 3: Set up Cloudflare

Follow [Set up Cloudflare](cloudflare.md). When you finish, you have a tunnel token in `.env` and a public address such as `https://vault-mcp.example.com`.

## Step 4: Start the server

1. Start all the containers in the background:

   ```bash
   docker compose up -d
   ```

   The `-d` option runs the containers in the background. They keep running after you close the terminal, and they restart on their own after a crash or a reboot. To make sure Docker itself starts when the machine starts, see [Start automatically](operations.md#start-automatically).

1. Check that everything works:

   ```bash
   scripts/check.sh https://vault-mcp.example.com
   ```

   Replace `vault-mcp.example.com` with your hostname. The output shows the following:

   - All containers are running, and `vault-mcp` is `healthy`.
   - For the Obsidian Sync setup: the sync mode is `bidirectional`.
   - The tunnel has 4 registered connections.
   - The MCP server lists 18 tools.
   - Your public address returns `401` with a `WWW-Authenticate` header. This means that Cloudflare Access is blocking requests that haven't signed in.

   <details>
   <summary>Windows PowerShell</summary>

   `check.sh` is a Bash script. Run it from WSL or Git Bash, or run the checks yourself:

   ```powershell
   docker compose ps
   Get-Content scripts/probe.mjs | docker compose exec -T vault-mcp node --input-type=module -
   ```

   </details>

## Step 5: Connect your MCP client

Follow [Compatible MCP clients](clients.md).

## What's next

- [Make it start automatically](operations.md#start-automatically) when the machine starts.
- Learn about the [safety modes](security.md), such as read-only and Inbox-only.
- Learn how to [stop it in an emergency](operations.md#stop-access-in-an-emergency).
