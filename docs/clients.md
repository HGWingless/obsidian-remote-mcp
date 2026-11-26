# Compatible MCP clients

An *MCP client* is an app that can use tools from an MCP server. For example, Claude is an MCP client. When you connect Claude to obsidian-remote-mcp, Claude can search, read, and write your notes.

Not every MCP client can use this server. A compatible client must be able to do all of the following:

- **Connect to a remote server by its web address.** Some clients can only start MCP servers as programs on your own computer.
- **Use the Streamable HTTP transport.** This is the standard way for MCP to work over the web. Some apps list it as **HTTP**.
- **Sign in with OAuth.** The client opens a browser window, you sign in through Cloudflare Access, and the client receives a token. Technically, the client must support OAuth 2.0 with dynamic client registration and resource indicators ([RFC 8707](https://datatracker.ietf.org/doc/html/rfc8707)).

## Clients

| Client | Status | Redirect URI to allow in Cloudflare |
|---|---|---|
| Claude: claude.ai, Claude Desktop, and the Claude mobile apps | Tested | `https://claude.ai/api/mcp/auth_callback` |
| Claude Code | Supports remote servers with OAuth. Not tested with this project. | `http://localhost:PORT/callback` |
| ChatGPT (developer mode) | Supports remote servers with OAuth. Not tested with this project. | See OpenAI's documentation |

Other clients that meet the requirements also work. For each client, add its redirect URI to the Managed OAuth settings in Cloudflare. See [Turn on Managed OAuth](cloudflare.md#turn-on-managed-oauth).

## Connect Claude

You add the connector once, on the web. It then works in claude.ai, Claude Desktop, and the Claude mobile apps.

> [!NOTE]
> Custom connectors are available on all Claude plans, including Free. On the Free plan, you can add one custom connector. On Team and Enterprise plans, an owner adds the connector in the organization settings first.

1. Open [claude.ai](https://claude.ai) in a web browser.
1. Go to **Customize > Connectors**.
1. Click **Add**, and then **Add custom connector**.
1. Enter a name, such as `Obsidian vault`, and the URL of your server:

   ```text
   https://vault-mcp.example.com/mcp
   ```

1. For the OAuth client, choose **Register automatically**.
1. Click **Add**, and then connect. A browser window opens with the Cloudflare Access sign-in page. Sign in.
1. Set the tools that change your vault to **Ask before use**:
   `write_note`, `patch_note`, `update_frontmatter`, `manage_tags`, `move_note`, `move_file`, and `delete_note`.

   With this setting, Claude asks you before it changes or deletes a note.

> [!IMPORTANT]
> You can't edit the sign-in settings of a connector after you add it. To change them, remove the connector and add it again.

> [!NOTE]
> Claude connects to your server from Anthropic's cloud, not from your device. That's why the server needs a public address on port 443, which Cloudflare provides.

## Connect Claude Code

These steps are based on the Claude Code documentation. They haven't been tested with this project.

1. Pick a port for the sign-in callback, such as `8765`.
1. In Cloudflare, add `http://localhost:8765/callback` to the allowed redirect URIs. See [Turn on Managed OAuth](cloudflare.md#turn-on-managed-oauth).
1. Add the server:

   ```bash
   claude mcp add --transport http --callback-port 8765 obsidian https://vault-mcp.example.com/mcp
   ```

1. In Claude Code, run `/mcp` and sign in.

For details, see [Connect Claude Code to tools via MCP](https://code.claude.com/docs/en/mcp).

## Connect ChatGPT

ChatGPT can connect to custom MCP servers in developer mode. This project hasn't been tested with ChatGPT. To try it, follow [OpenAI's guide](https://developers.openai.com/api/docs/guides/developer-mode), and add ChatGPT's redirect URI to the allowed redirect URIs in Cloudflare.

## Tools your client gets

The server offers 18 tools. In [read-only mode](security.md#read-only-mode), it offers only the 11 tools that don't change the vault.

| Reads your vault | Changes your vault |
|---|---|
| `read_note`, `read_multiple_notes`, `read_note_lines`, `search_notes`, `list_directory`, `get_note_outline`, `get_frontmatter`, `get_notes_info`, `get_vault_stats`, `list_all_tags`, `wiki_link` | `write_note`, `patch_note`, `update_frontmatter`, `manage_tags`, `move_note`, `move_file`, `delete_note` |

> [!WARNING]
> `delete_note` deletes a note permanently. With Obsidian Sync, the deletion reaches all your devices. Keep this tool set to **Ask before use**.
