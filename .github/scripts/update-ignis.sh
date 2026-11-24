#!/usr/bin/env bash
# Bumps the add-on to the newest nobbe/ignis image that has both amd64 and arm64.
#
# Writes to $GITHUB_OUTPUT (when set):
#   updated=true|false, current=<old>, latest=<new>, obsidian=<obsidian version>
#
# For testing, DOCKERHUB_TAGS_JSON and UPSTREAM_TAGS can point to local files
# instead of fetching from Docker Hub and GitHub.
set -euo pipefail

ROOT="${ROOT:-$(git rev-parse --show-toplevel)}"
IMAGE="nobbe/ignis"
UPSTREAM_REPO="https://github.com/Nystik-gh/ignis"

out() {
    echo "$1=$2"
    if [ -n "${GITHUB_OUTPUT:-}" ]; then
        echo "$1=$2" >> "$GITHUB_OUTPUT"
    fi
}

current="$(sed -n 's#^ARG BUILD_FROM=nobbe/ignis:\(.*\)$#\1#p' "$ROOT/ignis/Dockerfile")"
if [ -z "$current" ]; then
    echo "Could not read the current version from ignis/Dockerfile" >&2
    exit 1
fi

if [ -n "${DOCKERHUB_TAGS_JSON:-}" ]; then
    tags_json="$(cat "$DOCKERHUB_TAGS_JSON")"
else
    tags_json="$(curl -fsSL "https://hub.docker.com/v2/repositories/${IMAGE}/tags?page_size=100&ordering=last_updated")"
fi

# Plain release versions (X.Y.Z) that are published for both architectures.
latest="$(
    jq -r '
        .results[]
        | select(.name | test("^[0-9]+\\.[0-9]+\\.[0-9]+$"))
        | select([.images[]?.architecture] | (index("amd64") and index("arm64")))
        | .name
    ' <<< "$tags_json" | sort -V | tail -n 1
)"

if [ -z "$latest" ]; then
    echo "No multi-arch release tags found for ${IMAGE}" >&2
    exit 1
fi

out current "$current"
out latest "$latest"

if [ "$(printf '%s\n%s\n' "$current" "$latest" | sort -V | tail -n 1)" = "$current" ]; then
    echo "Already on the newest version ($current)."
    out updated false
    exit 0
fi

# Upstream tags look like v0.9.0+obsidian.1.14.4; read the Obsidian version from it.
if [ -n "${UPSTREAM_TAGS:-}" ]; then
    upstream_tags="$(cat "$UPSTREAM_TAGS")"
else
    upstream_tags="$(git ls-remote --tags "$UPSTREAM_REPO" | awk -F/ '{print $3}')"
fi

upstream_tag="$(grep -E "^v${latest//./\\.}\+obsidian\.[0-9.]+$" <<< "$upstream_tags" | head -n 1 || true)"
obsidian="${upstream_tag##*+obsidian.}"
if [ -z "$upstream_tag" ]; then
    obsidian=""
fi
out obsidian "$obsidian"

sed -i "s#^ARG BUILD_FROM=nobbe/ignis:${current}\$#ARG BUILD_FROM=nobbe/ignis:${latest}#" "$ROOT/ignis/Dockerfile"
# The app version may carry a dependency-update suffix (0.9.0.2, see
# bump-addon-version.sh); a new Ignis release replaces it with the plain version.
sed -i -E "s#^version: \"${current//./\\.}(\\.[0-9]+)?\"\$#version: \"${latest}\"#" "$ROOT/ignis/config.yaml"

grep -qxF "ARG BUILD_FROM=nobbe/ignis:${latest}" "$ROOT/ignis/Dockerfile"
grep -qxF "version: \"${latest}\"" "$ROOT/ignis/config.yaml"

if [ -n "$upstream_tag" ]; then
    notes_url="${UPSTREAM_REPO}/compare/v${current}+obsidian.$(
        grep -E "^v${current//./\\.}\+obsidian\.[0-9.]+$" <<< "$upstream_tags" | head -n 1 | sed 's#.*+obsidian\.##'
    )...${upstream_tag}"
    entry="- Update Ignis to ${latest} (Obsidian ${obsidian}). [Upstream changes](${notes_url})"
else
    entry="- Update Ignis to ${latest}. [Upstream releases](${UPSTREAM_REPO}/releases)"
fi

changelog="$ROOT/ignis/CHANGELOG.md"
{
    head -n 2 "$changelog"
    printf '## %s\n\n%s\n\n' "$latest" "$entry"
    tail -n +3 "$changelog"
} > "$changelog.new"
mv "$changelog.new" "$changelog"

out updated true
echo "Updated ${current} -> ${latest}."
