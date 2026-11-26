# syntax=docker/dockerfile:1
# Obsidian Sync client (obsidian-headless, the `ob` CLI).
#
# obsidian-headless is published by Obsidian as UNLICENSED. This Dockerfile
# installs it from npm at build time on your machine. Do not push the built
# image to a public registry: that would redistribute it.
ARG NODE_IMAGE=node:22-bookworm-slim
# The tag is pinned in the NODE_IMAGE default above (and in .env).
# hadolint ignore=DL3006
FROM ${NODE_IMAGE}

ARG OBSIDIAN_HEADLESS_VERSION=0.0.14
RUN npm install -g --no-fund --no-audit "obsidian-headless@${OBSIDIAN_HEADLESS_VERSION}" \
 && npm cache clean --force

# The node user in the official Node.js image (UID and GID 1000).
USER 1000:1000
ENV HOME=/home/node
WORKDIR /vault

CMD ["ob", "sync", "--path", "/vault", "--continuous"]
