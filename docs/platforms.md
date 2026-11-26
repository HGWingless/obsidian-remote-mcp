# Where it runs

obsidian-remote-mcp runs anywhere that runs Linux containers with Docker Compose. That includes Linux, macOS, Windows, cloud servers, and some NAS devices.

## Summary

| Platform | Docker software | Setup that fits | Tested |
|---|---|---|---|
| Linux server or PC | Docker Engine | Either | Yes (Debian, x86-64) |
| Mac | Docker Desktop or OrbStack | Local folder | No |
| Windows PC | Docker Desktop (WSL 2) | Local folder | No |
| Cloud server, such as a DigitalOcean Droplet | Docker Engine | Obsidian Sync | No, but it's the same as Linux |
| Synology NAS | Container Manager | Obsidian Sync | No |
| Raspberry Pi | Docker Engine, 64-bit OS | Obsidian Sync | No |

> [!NOTE]
> The machine must stay on and awake for your MCP client to reach your vault. A laptop that sleeps takes the server offline until it wakes up.

## Processor types

The containers run on **x86-64** (Intel and AMD, also called `amd64`) and **64-bit ARM** (`arm64`), such as Apple silicon, Raspberry Pi 4 and 5 with a 64-bit OS, and ARM cloud servers.

32-bit ARM isn't supported, because the cloudflared image has no 32-bit ARM version.

> [!NOTE]
> The project was tested on x86-64. Every part publishes an `arm64` version, but `arm64` hasn't been tested end to end.

## Linux

1. Install Docker Engine and the Compose plugin. Follow [Install Docker Engine](https://docs.docker.com/engine/install/) for your distribution.
1. Make Docker start at boot. See [Start automatically](operations.md#start-automatically).
1. Follow [Set up the server](setup.md).

For the local folder setup, set `PUID` and `PGID` in `.env` to the owner of your vault folder.

A Linux container on Proxmox (LXC) also works. Turn on the `nesting` and `keyctl` features for the container so that Docker can run inside it.

## Mac

Use the local folder setup to serve the vault that your Obsidian app already uses.

1. Install [Docker Desktop](https://docs.docker.com/desktop/setup/install/mac-install/) or [OrbStack](https://orbstack.dev/).
1. Follow [Set up the server](setup.md). Set `VAULT_DIR` to your vault's path, such as `/Users/alex/Documents/MyVault`.
1. Turn on start at login. See [Start automatically](operations.md#start-automatically).

> [!TIP]
> Docker Desktop shares your `/Users` folder with containers by default. If your vault is somewhere else, add its folder in **Docker Desktop > Settings > Resources > File sharing**.

> [!WARNING]
> If your vault is in iCloud Drive, macOS can remove local copies of files to save space. The server can't read a file that isn't on the Mac. Keep the vault folder downloaded, or turn off **Optimize Mac Storage**.

## Windows

Use the local folder setup to serve the vault that your Obsidian app already uses.

1. Install [Docker Desktop for Windows](https://docs.docker.com/desktop/setup/install/windows-install/) with the WSL 2 backend.
1. Follow [Set up the server](setup.md). In `.env`, use forward slashes in the path: `VAULT_DIR=C:/Users/alex/Documents/MyVault`.
1. Run the helper scripts, such as `scripts/check.sh`, from a WSL terminal or Git Bash.
1. Turn on start at sign-in. See [Start automatically](operations.md#start-automatically).

## Cloud servers

A small Linux cloud server works well with the Obsidian Sync setup, because it's always on. Examples include a DigitalOcean Droplet, an AWS Lightsail instance, or a Hetzner Cloud server.

1. Create a server with a current Ubuntu or Debian image.
1. Install Docker Engine, then follow [Set up the server](setup.md) with the **Obsidian Sync setup**.

You don't need to open any ports in the server's firewall. The tunnel connects out to Cloudflare.

> [!IMPORTANT]
> A cloud server stores your notes on someone else's hardware, as plain files. Choose a provider you trust, and turn on disk encryption if your provider offers it.

## Synology NAS

Synology's Container Manager can run Docker Compose files as a **Project**.

1. Check that your model offers Container Manager in Package Center, and that it uses an x86-64 or 64-bit ARM processor.
1. Install Container Manager.
1. Copy the repository to a shared folder on the NAS, for example `/volume1/docker/obsidian-remote-mcp`.
1. Create `.env` and follow the **Obsidian Sync setup** in [Set up the server](setup.md). To run the `docker compose` commands, connect to the NAS over SSH.
1. In Container Manager, create a project from the repository folder, or keep using `docker compose` over SSH.

Set `PUID` and `PGID` to the IDs of the DSM user that owns the folders. To find them, run `id USERNAME` over SSH.

> [!NOTE]
> Synology support isn't tested. Older versions of Container Manager may include an older Docker Compose. If a command fails, check the Compose version with `docker compose version`.

## Raspberry Pi

1. Install a 64-bit operating system, such as Raspberry Pi OS (64-bit).
1. Install Docker Engine. See [Install Docker Engine on Raspberry Pi OS](https://docs.docker.com/engine/install/raspberry-pi-os/).
1. Follow [Set up the server](setup.md) with the **Obsidian Sync setup**.

## Hardware needs

The server is small. The tested setup used 2 CPU cores and 1.5 GB of memory, with plenty to spare. With the notes-only option, a vault of about 1,000 notes used about 11 MB of disk space.
