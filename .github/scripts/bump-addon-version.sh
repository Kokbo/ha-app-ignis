#!/usr/bin/env bash
# Bumps the app version in ignis/config.yaml and adds a CHANGELOG.md entry, for a change
# to the image that is not a new Ignis release (for example a newer obsidian-headless).
# Home Assistant only rebuilds the app when this version changes.
#
# Versions are <Ignis version>.<n>: 0.9.0 -> 0.9.0.1 -> 0.9.0.2, and the next Ignis
# release (0.9.1) starts again without a suffix. AwesomeVersion, which the Supervisor
# uses, orders these as 0.9.0 < 0.9.0.1 < 0.9.1. A suffix like 0.9.0-1 would instead
# be a SemVer pre-release, which sorts *before* 0.9.0.
#
# Usage: bump-addon-version.sh "<changelog entry>"
# Prints the new version on stdout.
set -euo pipefail

ROOT="${ROOT:-$(git rev-parse --show-toplevel)}"
entry="${1:?usage: bump-addon-version.sh \"<changelog entry>\"}"
config="$ROOT/ignis/config.yaml"
changelog="$ROOT/ignis/CHANGELOG.md"

ignis="$(sed -n 's#^ARG BUILD_FROM=nobbe/ignis:\(.*\)$#\1#p' "$ROOT/ignis/Dockerfile")"
current="$(sed -n 's#^version: "\(.*\)"$#\1#p' "$config")"

if [ -z "$ignis" ] || [ -z "$current" ]; then
    echo "Could not read the Ignis version from ignis/Dockerfile or the version from ignis/config.yaml" >&2
    exit 1
fi

if [ "$current" = "$ignis" ]; then
    new="${ignis}.1"
elif [[ "$current" =~ ^${ignis//./\\.}\.([0-9]+)$ ]]; then
    new="${ignis}.$((BASH_REMATCH[1] + 1))"
else
    echo "Version ${current} in ignis/config.yaml does not belong to Ignis ${ignis}" >&2
    exit 1
fi

sed -i "s#^version: \"${current//./\\.}\"\$#version: \"${new}\"#" "$config"
grep -qxF "version: \"${new}\"" "$config"

{
    head -n 2 "$changelog"
    printf '## %s\n\n- %s\n\n' "$new" "$entry"
    tail -n +3 "$changelog"
} > "$changelog.new"
mv "$changelog.new" "$changelog"

echo "$new"
