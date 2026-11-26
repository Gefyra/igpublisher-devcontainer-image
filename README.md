# IG Publisher Dev Container Image

Dev container image for FHIR Implementation Guide projects. It carries the full toolchain **and** the devcontainer configuration, so an IG repository only has to point at it.

`ghcr.io/gefyra/igpublisher-devcontainer-image:latest`

## Contents

Built on [`ig-publisher-with-snapshot-support`](https://github.com/Gefyra/ig-publisher-action), which provides the toolchain itself:

| Tool | Purpose |
|---|---|
| IG Publisher (`/opt/ig/publisher.jar`) | Builds the IG |
| SUSHI (`sushi`) | FSH → FHIR resources |
| `fhir-pkg-tool` | Downloads and snapshots dependencies |
| Java 21, Node 24, Ruby + Jekyll | Runtimes the publisher needs |
| `python3` | Local preview server |
| `zip` / `unzip` | Download tasks |
| fontconfig + DejaVu/Liberation | The publisher renders images through `java.awt` |
| `sudo` | Installing things inside the container |

## Usage

A complete `devcontainer.json` for an IG project:

```json
{
  "name": "My IG",
  "image": "ghcr.io/gefyra/igpublisher-devcontainer-image:latest",
  "workspaceFolder": "/workspaces/${localWorkspaceFolderBasename}",
  "updateRemoteUserUID": true,
  "overrideCommand": true
}
```

Everything else comes from the image's [`devcontainer.metadata` label](https://containers.dev/implementors/spec/#image-metadata):

| Setting | Value |
|---|---|
| `remoteUser` | `runner` |
| `forwardPorts` | `8080` (IG preview) |
| `postCreateCommand` | Links the publisher, see below |
| `postStartCommand` | Reports the publisher's version and age |
| `customizations` | 10 VS Code extensions (FSH, FHIR tools, YAML, …) |

These are merged with the project's `devcontainer.json`: lifecycle commands are collected and **all** of them run, `forwardPorts` is unioned, extensions are added. On conflict the project's `devcontainer.json` wins.

## Tasks

The image ships wrappers for `.vscode/tasks.json`. They hold the logic so that `tasks.json` contains nothing but a command name and stays untouched when that logic changes:

| Command | What it does |
|---|---|
| `ig-update-publisher` | Fetches the current HL7 release into `input-cache/` |
| `ig-commit "<msg>"` | Checks the git identity, stages everything, commits |
| `ig-package` | Points at `output/full-ig.zip` for download |
| `ig-ai-package` | Points at `output/<lang>/ai.zip` (the guide as Markdown for AI tools) for download |
| `ig-json-resources` | Packs `fsh-generated/resources/*.json` into a ZIP |

The remaining tasks call the tools directly: `sushi`, `./_genonce.sh -no-sushi`, `fhir-pkg-tool`, `python3 -m http.server 8080`.

## How the publisher is managed

The image already contains a publisher at `/opt/ig/publisher.jar` (~220 MB). The HL7 build scripts (`_genonce.sh` and friends) look for it in `input-cache/publisher.jar` first and in `../publisher.jar` second.

`post-create.sh` therefore links **`../publisher.jar`** — in `/workspaces/`, next to the IG's folder — to the image's jar, instead of copying the file or downloading it again:

- The jar exists once instead of twice.
- On every container rebuild the link points at the new image's version — there is no frozen copy.
- The link lies outside the IG's folder. IG Publisher 3.x stops on any symbolic link that leads *out of* the IG's folder (unless run with `-allow-external-links`), which is why earlier versions of this image, which linked `input-cache/publisher.jar`, broke with it. `post-create.sh` removes such a leftover link.
- The link cannot be written to, because `/opt` belongs to root. `ig-update-publisher` therefore takes it away while `_updatePublisher.sh` downloads a real file into `input-cache/`, and puts it back afterwards.

After a manual update there are two jars (~440 MB), and the one in `input-cache/` wins. Once the image has caught up, the next rebuild removes that copy and frees the space — but only for an equal or newer version, so a silent downgrade cannot happen.

## Updating

The image is rebuilt automatically when a new IG Publisher release appears (chain: HL7 release → `ig-publisher` → `ig-publisher-with-snapshot-support` → this image, typically within 24 hours). Containers do not pick that up by themselves — `:latest` is a moving tag.

**For IG authors: [Staying up to date](https://github.com/Gefyra/IGPublisherDevContainer#staying-up-to-date)** in the template README.

## Testing changes

Push to a `test/**` branch to build `:test` instead of `:latest`. That build sits on `ig-publisher-with-snapshot-support:test`, which a `test/**` branch in [ig-publisher-action](https://github.com/Gefyra/ig-publisher-action) publishes, so changes to the toolchain and to this image can be tried together. Point a test repository's `devcontainer.json` at `:test`. Neither `:latest`, the `sushi-*` tags nor the build cache are touched.

## Migrating an existing project

Projects created from the [template](https://github.com/Gefyra/IGPublisherDevContainer) before this change still carry the configuration themselves. They keep working after a rebuild — with **one exception**.

### Required: one task

In the old `tasks.json` the "Update IG Publisher" task calls `./_updatePublisher.sh -y` directly. That writes with `curl -o` through the image's link (`../publisher.jar`) into root-owned `/opt` and fails with `curl: (23) Failure writing output to destination`. Nothing is lost, but the task only works again after this change in `.vscode/tasks.json`:

```json
{
  "label": "Update IG Publisher",
  "type": "shell",
  "command": "ig-update-publisher"
}
```

`post-create.sh` detects the situation and points it out when the container is created.

### Optional: clean up

While in the repository anyway, the remaining duplication can go. The benefit: future improvements to this logic reach the project through a rebuild alone.

- Reduce `.devcontainer/devcontainer.json` to the form above — `remoteUser`, `forwardPorts`, `postCreateCommand`, `postStartCommand` and the extension list come from the image.
- Point the "Git: Commit Changes", "Download: IG Package" and "Download: JSON Resources" tasks at `ig-commit "${input:commitMessage}"`, `ig-package` and `ig-json-resources`.

`.vscode/tasks.json` itself has to stay in the repository — VS Code reads it from the workspace, it cannot come from the image. Thanks to the wrappers it then holds only command names and needs no further attention when the logic changes.

## Working on the image

```bash
docker build -f .devcontainer/Dockerfile -t igpub-dc-test:local .

# inspect the metadata label
docker inspect igpub-dc-test:local \
  --format '{{index .Config.Labels "devcontainer.metadata"}}' | python3 -m json.tool

# run the lifecycle scripts against a simulated workspace
docker run --rm igpub-dc-test:local bash -c '
  mkdir -p /tmp/ws && cd /tmp/ws && touch ig.ini
  bash /usr/local/share/ig-devcontainer/post-create.sh
  bash /usr/local/share/ig-devcontainer/post-start.sh'
```

The scripts live in `.devcontainer/scripts/` and end up at `/usr/local/share/ig-devcontainer/` in the image; the four `ig-*` wrappers are additionally linked into `/usr/local/bin/`. They expect the working directory to be the workspace folder, which is how both devcontainer lifecycle commands and VS Code tasks invoke them.

A push to `main` touching `.devcontainer/**` builds and publishes the image. A new base image also triggers the build through `repository_dispatch`.
