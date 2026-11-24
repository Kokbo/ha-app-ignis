#!/usr/bin/env bash
# Run by the "Release dependency updates" workflow after a push to main that changed
# ignis/. If that commit came from a merged Renovate pull request (merged by Renovate or
# by hand) that did not change the version itself, it bumps the version and changelog
# with bump-addon-version.sh and pushes the result to main, so Home Assistant offers
# the update.
#
# Needs GH_TOKEN, REPO (owner/name) and SHA (the pushed commit), and a checkout whose
# git credentials can push to main.
set -euo pipefail

: "${REPO:?REPO is required}" "${SHA:?SHA is required}"

pr="$(gh api "repos/${REPO}/commits/${SHA}/pulls" --jq '
    [.[] | select(.merged_at != null and (.head.ref | startswith("renovate/")))]
    | first // empty
    | "\(.number)\t\(.title)"')"

if [ -z "$pr" ]; then
    echo "${SHA} is not from a merged Renovate pull request; nothing to release."
    exit 0
fi

IFS=$'\t' read -r number title <<< "$pr"
title="$(tr -d '\000-\037' <<< "$title")"

if gh api --paginate "repos/${REPO}/pulls/${number}/files" \
    --jq '.[] | select(.filename == "ignis/config.yaml") | .patch // ""' \
    | grep -qE '^\+version:'; then
    echo "Pull request #${number} already changed the version; nothing to do."
    exit 0
fi

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"

# If the push is rejected because main moved, start again from the new main.
for attempt in 1 2 3; do
    git fetch --quiet origin main
    git reset --quiet --hard origin/main

    if grep -qF "(#${number})" ignis/CHANGELOG.md; then
        echo "Pull request #${number} is already released."
        exit 0
    fi

    version="$(bash .github/scripts/bump-addon-version.sh "${title} (#${number})")"
    git commit --quiet -am "Release ${version}" -m "Dependency update from #${number}."

    if git push --quiet origin HEAD:main; then
        echo "Released ${version} for #${number}."
        if [ -n "${GITHUB_OUTPUT:-}" ]; then
            echo "version=${version}" >> "$GITHUB_OUTPUT"
        fi
        exit 0
    fi

    echo "Push rejected (attempt ${attempt}); retrying on the latest main." >&2
    sleep $((attempt * 5))
done

echo "Could not push the release for #${number}." >&2
exit 1
