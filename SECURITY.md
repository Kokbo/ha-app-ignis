# Security policy

## Reporting a vulnerability

Please report security problems privately through
[GitHub's private vulnerability reporting](https://github.com/Kokbo/ha-app-ignis/security/advisories/new),
not in a public issue.

This repository packages Ignis as a Home Assistant app. Report a problem here if it is in
this repository: the Dockerfile, the start script, the option handling or the workflows.
Problems in Ignis itself belong with [Ignis](https://github.com/Nystik-gh/ignis), and problems
in Obsidian with [Obsidian](https://obsidian.md/security). If you are not sure, report it here.

## Supported versions

Only the latest version is supported. Home Assistant offers the update as soon as it is
released.

## Known limitation

Ignis has no login of its own. Anyone who can reach port 8080 can use your vaults, so keep
it behind authentication; see the [app documentation](ignis/DOCS.md).
