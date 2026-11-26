// Local MCP smoke test, run inside the vault-mcp container:
//   docker compose exec -T vault-mcp node --input-type=module - < scripts/probe.mjs
// Sends initialize, then tools/list, to http://127.0.0.1:8000/mcp and prints
// the tool names. (`docker cp` won't work: the container's rootfs is read-only.)
const url = "http://127.0.0.1:8000/mcp";
const headers = { "content-type": "application/json", accept: "application/json, text/event-stream" };

async function rpc(body, session) {
  const res = await fetch(url, {
    method: "POST",
    headers: session ? { ...headers, "mcp-session-id": session } : headers,
    body: JSON.stringify(body),
  });
  const text = (await res.text()).trim();
  let json = null; // notifications get 202 with no body
  if (text.startsWith("{")) json = JSON.parse(text);
  else if (text) json = JSON.parse(text.split("\n").filter((l) => l.startsWith("data:")).map((l) => l.slice(5)).pop());
  return { session: res.headers.get("mcp-session-id"), json, status: res.status };
}

const init = await rpc({
  jsonrpc: "2.0", id: 1, method: "initialize",
  params: { protocolVersion: "2025-06-18", capabilities: {}, clientInfo: { name: "probe", version: "1" } },
});
console.log(`initialize: HTTP ${init.status}, server ${init.json?.result?.serverInfo?.name} ${init.json?.result?.serverInfo?.version}`);
await rpc({ jsonrpc: "2.0", method: "notifications/initialized" }, init.session);
const list = await rpc({ jsonrpc: "2.0", id: 2, method: "tools/list", params: {} }, init.session);
const tools = list.json?.result?.tools ?? [];
console.log(`tools/list: ${tools.length} tools`);
for (const t of tools) console.log(`  ${t.name}`);
process.exit(tools.length > 0 ? 0 : 1);
