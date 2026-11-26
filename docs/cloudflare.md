# Set up Cloudflare

This page shows you how to put your MCP server on the internet safely. You create three things in Cloudflare:

- A **tunnel**, which connects your machine to Cloudflare without opening ports.
- An **Access application**, which decides who can sign in.
- **Managed OAuth**, which lets MCP clients like Claude sign in for you.

Everything on this page works on the free Cloudflare Zero Trust plan.

> [!NOTE]
> Cloudflare sometimes moves things in its dashboard. For example, tunnels also appear under **Networking > Tunnels** in the main Cloudflare dashboard. If a menu name doesn't match, use the search in the dashboard, or see the Cloudflare documentation linked at the end of this page.

## Before you begin

- Add your domain to Cloudflare, and use Cloudflare DNS for it.
- Pick a hostname for the server. This page uses `vault-mcp.example.com`. Replace it with your own hostname everywhere.

## Create a Zero Trust organization

1. In the [Cloudflare dashboard](https://dash.cloudflare.com/), open **Zero Trust**.
1. If you don't have an organization yet, create one. When asked for a plan, choose **Free**.
1. Choose how you sign in. Go to **Integrations > Identity providers**. **One-time PIN** is on by default: Cloudflare emails you a code. You can also add Google, GitHub, or another provider.

## Create the tunnel

1. Go to **Networks > Tunnels**, and click **Create a tunnel**.
1. Choose **Cloudflared**, and name the tunnel, for example `vault-mcp`.
1. On the install screen, find the command that contains `--token`. Copy only the token, which is the long string after `--token` that starts with `eyJ`.
1. Save the token in `.env` on your server. To keep it out of your shell history, run this from the repository folder:

   ```bash
   read -rsp 'Tunnel token: ' TOKEN; echo
   case "$TOKEN" in eyJ*) echo "Token looks right." ;; *) echo "Check the token. It should start with eyJ." ;; esac
   sed -i.bak "s|^TUNNEL_TOKEN=.*|TUNNEL_TOKEN=$TOKEN|" .env && rm .env.bak
   unset TOKEN
   ```

   On Windows, paste the token into `.env` with a text editor.

1. Add a public hostname (Cloudflare may call it a **published application route**) with these values:

   | Field | Value |
   |---|---|
   | Subdomain | `vault-mcp` |
   | Domain | `example.com` |
   | Path | Leave empty |
   | Service type | `HTTP` |
   | Service URL | `vault-mcp:8000` |

   `vault-mcp` is the name of the MCP server container. The tunnel reaches it over a private Docker network. Cloudflare also creates the DNS record for the hostname.

## Create the Access application

1. Go to **Access controls > Applications**, and click **Add an application**.
1. Choose **Self-hosted**.
1. Name the application, for example `vault-mcp`.
1. Add the hostname `vault-mcp.example.com`. Leave the path empty.
1. Add a policy:
   - **Action:** Allow
   - **Include:** Emails, with your own email address only
1. Choose the sign-in methods from [Create a Zero Trust organization](#create-a-zero-trust-organization).
1. Save the application.

## Turn on Managed OAuth

Managed OAuth lets an MCP client sign in through Access with a normal OAuth flow. Without it, MCP clients can't get past the Access sign-in page.

1. In **Access controls > Applications**, edit your application.
1. Open **Advanced settings**, and turn on **Managed OAuth**.
1. In the Managed OAuth settings, limit the allowed redirect URIs to the clients you use. For Claude, add:

   ```text
   https://claude.ai/api/mcp/auth_callback
   ```

   For other clients, see [Compatible MCP clients](clients.md).

1. Save. Then copy the application's **Application Audience (AUD) tag**. You need it in the next section.

## Check the sign-in at the tunnel too

This step makes the tunnel reject any request that didn't pass Access. If you ever change the Access application by mistake, your vault stays closed.

1. Go back to **Networks > Tunnels**, and edit your tunnel's public hostname.
1. In the origin settings, find **Access**, and turn on **Protect with Access** (also called **Enforce Access JSON Web Token (JWT) validation**).
1. Enter your team name and the AUD tag from the previous section.
1. Save.

## Check your work

After you [start the server](setup.md#step-4-start-the-server), run these commands from a computer outside your home network:

```bash
curl -si -X POST https://vault-mcp.example.com/mcp | grep -iE '^HTTP/|^www-authenticate'
```

You see `401` and a `WWW-Authenticate` header. This is correct: Access blocks requests that haven't signed in.

```bash
curl -s https://vault-mcp.example.com/.well-known/oauth-authorization-server
```

You see JSON that includes `registration_endpoint`. This means that MCP clients can register and sign in.

> [!TIP]
> If these commands work from outside your network but sign-in fails at home, see [Sign-in fails on your home network](troubleshooting.md#sign-in-fails-on-your-home-network).

## How sign-in works

<details>
<summary>Show the sign-in steps</summary>

1. The MCP client sends a request without a token. Access answers `401`, with a `WWW-Authenticate` header that points to its sign-in information.
1. The client registers itself with Access. Access accepts only the redirect URIs that you allowed.
1. Your browser opens the Access sign-in page. You sign in, for example with a one-time PIN.
1. Access sends your browser back through `https://vault-mcp.example.com/cdn-cgi/access/authorized`, then to the client.
1. The client receives an access token and sends it with every request. Access checks it, and the tunnel checks Access's signed token again before the request reaches your vault.

</details>

## Related links

- [Managed OAuth](https://developers.cloudflare.com/cloudflare-one/access-controls/applications/http-apps/managed-oauth/) (Cloudflare documentation)
- [Self-hosted applications](https://developers.cloudflare.com/cloudflare-one/access-controls/applications/http-apps/self-hosted-public-app/) (Cloudflare documentation)
