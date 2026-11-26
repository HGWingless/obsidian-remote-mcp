# Security policy

obsidian-remote-mcp puts a personal notes vault on the internet. Please report security problems privately, so that they can be fixed before anyone else learns about them.

## Report a problem

> [!IMPORTANT]
> Don't report security problems in a public issue, pull request, or discussion.

1. Go to the repository's [Security tab](https://github.com/HGWingless/obsidian-remote-mcp/security).
1. Click **Report a vulnerability**.
1. Describe the problem, how to reproduce it, and what an attacker could do with it.

Don't include your own tunnel token, Access tokens, Obsidian login, or encryption password in the report.

## What's in scope

This policy covers the files in this repository:

- The Docker Compose files and the Dockerfiles.
- The container entrypoint and the scripts in `scripts/`.
- The setup and security guidance in the documentation, if following it leaves a vault exposed.

## What's out of scope

Problems in the projects that this repository builds on belong to those projects. Report them there:

- [MCPVault](https://github.com/bitbonsai/mcpvault)
- [supergateway](https://github.com/supercorp-ai/supergateway)
- [cloudflared](https://github.com/cloudflare/cloudflared) and Cloudflare Access: follow the security policy in the cloudflared repository
- obsidian-headless and Obsidian Sync: contact [Obsidian](https://obsidian.md/)

If you're not sure where a problem belongs, report it here, and we'll help find the right place.

## What happens next

This is a small, volunteer-run project. Reports are read and handled as time allows, and there's no set response time.
