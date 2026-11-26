# syntax=docker/dockerfile:1
# MCPVault (stdio MCP server over a folder of Markdown) wrapped by
# supergateway, which serves it as Streamable HTTP on :8000 at /mcp.
ARG NODE_IMAGE=node:22-bookworm-slim
# The tag is pinned in the NODE_IMAGE default above (and in .env).
# hadolint ignore=DL3006
FROM ${NODE_IMAGE}

ARG MCPVAULT_VERSION=0.18.3
ARG SUPERGATEWAY_VERSION=4.2.1
RUN npm install -g --no-fund --no-audit \
      "@bitbonsai/mcpvault@${MCPVAULT_VERSION}" \
      "supergateway@${SUPERGATEWAY_VERSION}" \
 && npm cache clean --force

COPY --chmod=0755 entrypoint.sh /usr/local/bin/vault-mcp-entrypoint

# The node user in the official Node.js image (UID and GID 1000).
USER 1000:1000
ENV HOME=/home/node
EXPOSE 8000

ENTRYPOINT ["/usr/local/bin/vault-mcp-entrypoint"]
