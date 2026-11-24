# syntax=docker/dockerfile:1
# Upstream publishes nobbe/ignis as a multi-arch image (linux/amd64 + linux/arm64).
# This default is the base image (build.yaml is deprecated, so the Supervisor no
# longer passes BUILD_FROM). Keep it in step with version in config.yaml;
# .github/scripts/update-ignis.sh updates both.
ARG BUILD_FROM=nobbe/ignis:0.9.0
FROM ${BUILD_FROM}

LABEL \
    org.opencontainers.image.title="Home Assistant App: Ignis (Obsidian)" \
    org.opencontainers.image.description="Obsidian in the browser, with your vaults stored on Home Assistant" \
    org.opencontainers.image.source="https://github.com/Kokbo/ha-app-ignis" \
    org.opencontainers.image.licenses="AGPL-3.0-only"

ARG OBSIDIAN_HEADLESS_VERSION=0.0.14
ARG UPSTREAM_ENTRYPOINT=/app/apps/ignis-server/scripts/entrypoint.sh

# Everything that must survive a restart lives in the add-on's /data:
#   /data/ignis         Ignis server settings
#   /data/obsidian-app  the Obsidian app, downloaded once per Obsidian version
#   /data/config        obsidian-headless login (Obsidian Sync)
# The base image declares /app/obsidian-app as a VOLUME, which would be a new empty
# anonymous volume on every start, so Obsidian is kept in /data instead.
ENV DATA_ROOT=/data/ignis \
    OBSIDIAN_ASSETS_PATH=/data/obsidian-app \
    XDG_CONFIG_HOME=/data/config \
    VAULT_ROOT=/share/obsidian

# Point the upstream entrypoint at the /data paths above. The grep checks make the
# build fail if a new upstream release changes these lines, instead of silently
# falling back to non-persistent paths.
# The single quotes are deliberate: sed must write the literal $VARS into the script.
# hadolint ignore=SC2016
RUN sed -i \
        -e 's#^OBSIDIAN_DIR="/app/obsidian-app"$#OBSIDIAN_DIR="${OBSIDIAN_ASSETS_PATH:-/app/obsidian-app}"#' \
        -e 's#^mkdir -p /app/data$#mkdir -p "$DATA_ROOT" "$VAULT_ROOT"#' \
        -e 's#^for dir in /app/obsidian-app /app/data /vaults; do$#for dir in "$OBSIDIAN_DIR" "$DATA_ROOT" "$VAULT_ROOT"; do#' \
        "${UPSTREAM_ENTRYPOINT}" \
    && grep -qxF 'OBSIDIAN_DIR="${OBSIDIAN_ASSETS_PATH:-/app/obsidian-app}"' "${UPSTREAM_ENTRYPOINT}" \
    && grep -qxF 'mkdir -p "$DATA_ROOT" "$VAULT_ROOT"' "${UPSTREAM_ENTRYPOINT}" \
    && grep -qxF 'for dir in "$OBSIDIAN_DIR" "$DATA_ROOT" "$VAULT_ROOT"; do' "${UPSTREAM_ENTRYPOINT}"

# Upstream installs obsidian-headless (Obsidian Sync) with npm on every start. This
# image is built on your own machine, so install it here once instead.
RUN npm install -g --prefix /usr/local "obsidian-headless@${OBSIDIAN_HEADLESS_VERSION}" --no-audit --no-fund \
    && ob --version

COPY rootfs/ /
RUN chmod 0755 /run.sh

# Shell form on purpose, for the "|| exit 1".
# hadolint ignore=DL3025
HEALTHCHECK --interval=60s --timeout=5s --start-period=120s \
    CMD curl -fsS -o /dev/null http://127.0.0.1:8080/api/version || exit 1

ENTRYPOINT ["/run.sh"]
CMD []
