# Security and safety modes

This page explains what protects your vault, what doesn't, and how to limit what MCP clients can change.

## Default: full read and write

By default, a client that signs in can read, create, edit, move, and delete notes anywhere in the vault. This is what most people want: an AI app that can file notes, fix links, and update your daily note.

If you want less, use one of the two optional safety modes:

| Mode | Clients can read | Clients can change | Turn on with |
|---|---|---|---|
| Full (default) | The whole vault | The whole vault | Nothing to do |
| [Read-only](#read-only-mode) | The whole vault | Nothing | `MCPVAULT_READ_ONLY=true` |
| [Inbox-only](#inbox-only-mode) | The whole vault | One folder | `compose.inbox-only.yaml` |

> [!TIP]
> Whichever mode you use, set the tools that change your vault to **Ask before use** in your MCP client. See [Connect Claude](clients.md#connect-claude).

## Read-only mode

In read-only mode, the server offers only the 11 tools that read the vault. Clients can search and read notes, but they can't change anything.

Use it when you only want AI apps to look things up in your notes.

1. In `.env`, set:

   ```text
   MCPVAULT_READ_ONLY=true
   ```

1. Apply the change:

   ```bash
   docker compose up -d vault-mcp
   ```

1. In your MCP client, reconnect or refresh the server, so that it loads the shorter tool list.

## Inbox-only mode

In Inbox-only mode, clients can read the whole vault but can write to only one folder, such as `Inbox`. They can't edit, move, or delete any note outside that folder.

Use it in these cases:

- You're starting out and want to see how an AI app uses your vault before you trust it with more.
- Your vault holds notes you never want an AI app to change, but you still want it to capture new ideas, tasks, or meeting notes for you to file later.

The limit doesn't depend on the client or the MCP server behaving well. Docker gives the server a read-only view of the vault, with only the Inbox folder writable. The operating system refuses any other write.

### Turn on Inbox-only mode

1. Make sure the folder exists in your vault. The default name is `Inbox`. To use another folder, set `INBOX_DIR` in `.env`, for example `INBOX_DIR=Capture`.
1. Start the server with the Inbox-only file added:

   ```bash
   docker compose -f compose.yaml -f compose.inbox-only.yaml up -d vault-mcp
   ```

1. Check it. Ask your client to create a test note outside the Inbox folder. The request fails with a read-only error. A note in the Inbox folder works.

> [!IMPORTANT]
> Add `-f compose.yaml -f compose.inbox-only.yaml` every time you run `docker compose up` for `vault-mcp`. A plain `docker compose up -d` turns Inbox-only mode off. To avoid this, add `COMPOSE_FILE=compose.yaml:compose.inbox-only.yaml` to `.env`. On Windows, use a semicolon (`;`) instead of the colon.

> [!NOTE]
> If you delete and re-create the Inbox folder, for example on another device that syncs back, re-create the container so that it sees the new folder:
>
> ```bash
> docker compose -f compose.yaml -f compose.inbox-only.yaml up -d --force-recreate vault-mcp
> ```

With the Obsidian Sync setup, only the MCP server is limited. The `ob-sync` container still writes your whole vault, because it brings in changes from your other devices.

### Turn off Inbox-only mode

Remove `COMPOSE_FILE` from `.env` if you added it, then run:

```bash
docker compose up -d vault-mcp
```

## What protects your vault

| Layer | What it does |
|---|---|
| Cloudflare Tunnel | The machine accepts no incoming connections. You don't open any ports. |
| Cloudflare Access | Only the email addresses in your Access policy can sign in. Everyone else gets `401`. |
| Managed OAuth redirect list | Only the client apps you allowed can complete sign-in. |
| Access token check at the tunnel | The tunnel rejects requests that didn't pass Access, even if the Access application is changed by mistake. |
| Private Docker network | The MCP server has no published port. Only the tunnel container can reach it. |
| Container limits | Containers run as a regular user, with no extra Linux capabilities. The MCP server's system files are read-only. |
| MCPVault | Refuses paths outside the vault, and refuses the `.obsidian` folder and hidden files. |

## What it doesn't protect

> [!WARNING]
> Read these before you put a sensitive vault on a server.

- **Anyone who signs in gets the same access.** Access decides who signs in, not what they can do. Keep your Access policy to your own email address.
- **Your notes are plain files on the machine.** Anyone with access to the machine or its disks can read them. On a cloud server or a shared NAS, choose a provider and an admin you trust.
- **The AI provider sees what it reads.** When a client reads a note, the note's text goes to that client's service. Follow that provider's data policy.
- **`OB_HOME_DIR` holds your Obsidian login.** In the Obsidian Sync setup, this folder holds the session that syncs your vault. For an encrypted vault, it also holds what the sync client needs to decrypt it. Protect it like a password file, and don't back it up to shared storage.
- **`.env` holds your tunnel token.** Anyone with the token can run your tunnel. Keep the file private (`chmod 600 .env`), and never commit it.
- **Hidden folders aren't private.** `MCPVAULT_EXCLUDE` only hides folders from search and folder listings. A client can still open a file in them if it knows the path. To keep notes away from AI apps, keep them out of `VAULT_DIR`. With the Obsidian Sync setup, use `--excluded-folders` in `ob sync-config`.
- **Deletions are real.** `delete_note` removes a note from disk. With Obsidian Sync, the deletion reaches your other devices. Obsidian Sync keeps version history, and you can restore deleted notes from it. For the local folder setup, keep your own backups.

## Stop access quickly

To cut off all MCP access at once, stop the MCP server:

```bash
docker compose stop vault-mcp
```

For more options, see [Stop access in an emergency](operations.md#stop-access-in-an-emergency).
