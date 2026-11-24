# Ignis – Home Assistant app

[![CI][ci-badge]][ci-url]
[![Ignis version][version-badge]](ignis/CHANGELOG.md)
![Supports aarch64 Architecture][aarch64-shield]
![Supports amd64 Architecture][amd64-shield]

Run [Ignis](https://github.com/Nystik-gh/ignis) on Home Assistant: the real Obsidian
app in a browser tab, with your vaults stored in `/share/obsidian`. (Home Assistant
called apps "add-ons" before 2026.2.)

[![Open your Home Assistant instance and show the add app repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2FKokbo%2Fha-app-ignis)

## Install in Home Assistant

1. Click the button above, or go to **Settings → Apps → App store → ⋮ → Repositories** and add
   `https://github.com/Kokbo/ha-app-ignis`.
2. Install **Ignis (Obsidian)**. The image is built on your machine from the official
   multi-arch `nobbe/ignis` image (a few minutes).
3. Start it and click **Open web UI**. The first start downloads Obsidian (a minute or
   two).

Supported: `amd64` and `aarch64` (Raspberry Pi 4/5, HA Green/Yellow).

Ignis has no login. Read the [app documentation](ignis/DOCS.md) for security,
HTTPS and options before exposing it.

## Updating to a new Ignis release

The **Update Ignis** workflow does this automatically. Every day it checks Docker Hub
for a newer `nobbe/ignis` release published for both amd64 and arm64. When it finds
one, it pushes the version bump to a temporary `update-ignis-<version>` branch, runs the
full CI there (build and start on amd64 and aarch64), and only then pushes the commit to
`main`. Home Assistant then offers the update in the app store.

If CI fails, `main` is left alone and the `update-ignis-<version>` branch stays so you
can see what broke; delete it to let the workflow try that version again. Run the
workflow by hand under **Actions → Update Ignis → Run workflow**.

To update by hand:

1. Change the `nobbe/ignis:<version>` tag in `ARG BUILD_FROM` in `ignis/Dockerfile`.
2. Set the same `version` in `ignis/config.yaml` and add a `CHANGELOG.md` entry.
3. Push. CI builds both architectures; the build fails if the upstream entrypoint
   changed in a way the app's patch no longer matches.

## Repository layout

```
repository.yaml                         app repository metadata
ignis/config.yaml                       app manifest and options
ignis/Dockerfile                        base image (BUILD_FROM) and adaptations to Home Assistant
ignis/rootfs/run.sh                     maps options to Ignis environment variables
ignis/rootfs/usr/local/lib/ha-addon/    option parser
ignis/translations/en.yaml              option labels in the Home Assistant UI
```

## Credits

Ignis is made by [Nystik-gh](https://github.com/Nystik-gh/ignis) and licensed under
AGPL-3.0. Obsidian is made by Dynalist Inc. and is downloaded from its official
releases; it is not included in this repository.

[ci-badge]: https://github.com/Kokbo/ha-app-ignis/actions/workflows/ci.yaml/badge.svg
[ci-url]: https://github.com/Kokbo/ha-app-ignis/actions/workflows/ci.yaml
[version-badge]: https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2FKokbo%2Fha-app-ignis%2Fmain%2Fignis%2Fconfig.yaml&query=%24.version&label=ignis
[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
