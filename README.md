# IG Publisher Dev Container Image

Dev-Container-Image für FHIR-Implementation-Guide-Projekte. Es bringt die komplette Toolchain **und** die Devcontainer-Konfiguration mit, sodass ein IG-Repository nur noch auf das Image zeigen muss.

`ghcr.io/gefyra/igpublisher-devcontainer-image:latest`

## Inhalt

Aufgebaut auf [`ig-publisher-with-snapshot-support`](https://github.com/Gefyra/ig-publisher-action), das die eigentliche Toolchain liefert:

| Werkzeug | Zweck |
|---|---|
| IG Publisher (`/opt/ig/publisher.jar`) | IG-Build |
| SUSHI (`sushi`) | FSH → FHIR-Ressourcen |
| `fhir-pkg-tool` | Abhängigkeiten laden und snapshotten |
| Java 21, Node 20, Ruby + Jekyll | Laufzeit des Publishers |
| `python3` | lokaler Preview-Server |
| `zip` / `unzip` | Download-Tasks |
| fontconfig + DejaVu/Liberation | der Publisher rendert Bilder über `java.awt` |
| `sudo` | Nachinstallieren im Container |

## Verwendung

Eine vollständige `devcontainer.json` für ein IG-Projekt:

```json
{
  "name": "Mein IG",
  "image": "ghcr.io/gefyra/igpublisher-devcontainer-image:latest",
  "workspaceFolder": "/workspaces/${localWorkspaceFolderBasename}",
  "updateRemoteUserUID": true,
  "overrideCommand": true
}
```

Alles Weitere liefert das Image über sein [`devcontainer.metadata`-Label](https://containers.dev/implementors/spec/#image-metadata):

| Einstellung | Wert |
|---|---|
| `remoteUser` | `runner` |
| `forwardPorts` | `8080` (IG Preview) |
| `postCreateCommand` | verlinkt den Publisher, siehe unten |
| `postStartCommand` | meldet Publisher-Version und -Alter |
| `customizations` | 10 VS-Code-Extensions (FSH, FHIR-Tools, YAML, …) |

Die Werte werden mit denen der `devcontainer.json` zusammengeführt: Lifecycle-Kommandos werden gesammelt und **alle** ausgeführt, `forwardPorts` vereinigt, Extensions ergänzt. Wo es einen Konflikt gibt, gewinnt die `devcontainer.json` des Projekts.

## Tasks

Für `.vscode/tasks.json` stehen im Image Wrapper bereit. Sie kapseln die Logik, damit `tasks.json` nur einen Kommandonamen enthält und bei künftigen Änderungen unangetastet bleibt:

| Kommando | Tut |
|---|---|
| `ig-update-publisher` | lädt das aktuelle HL7-Release nach `input-cache/` |
| `ig-commit "<msg>"` | prüft die Git-Identität, staged alles, committet |
| `ig-package` | weist auf `output/full-ig.zip` zum Download hin |
| `ig-json-resources` | packt `fsh-generated/resources/*.json` als ZIP |

Die übrigen Tasks rufen die Werkzeuge direkt auf: `sushi`, `./_genonce.sh -no-sushi`, `fhir-pkg-tool`, `python3 -m http.server 8080`.

## Wie der Publisher verwaltet wird

Das Image enthält bereits einen Publisher unter `/opt/ig/publisher.jar` (~220 MB). Die Build-Skripte erwarten ihn aber unter `input-cache/publisher.jar`.

`post-create.sh` legt deshalb einen **Symlink** an, statt die Datei zu kopieren oder erneut herunterzuladen. Das hat drei Effekte:

- Das Jar existiert einmal statt zweimal.
- Bei jedem Container-Rebuild zeigt der Link automatisch auf die Version des neuen Images — es gibt keine eingefrorene Kopie.
- Der Link ist nicht beschreibbar, weil `/opt` root gehört. Deshalb entfernt `ig-update-publisher` ihn zuerst und legt eine echte Datei an.

Nach einem manuellen Update liegen wieder zwei Jars vor (~440 MB). Sobald das Image aufgeholt hat, tauscht `post-create.sh` beim nächsten Rebuild die Kopie gegen den Link zurück und gibt den Platz frei — aber nur gegen eine gleiche oder neuere Version, ein stilles Downgrade ist ausgeschlossen.

## Aktualisieren

Das Image wird automatisch neu gebaut, wenn ein neues IG-Publisher-Release erscheint (Kette: HL7-Release → `ig-publisher` → `ig-publisher-with-snapshot-support` → dieses Image, typischerweise unter 24 Stunden). Container ziehen das aber nicht von selbst — `:latest` ist ein bewegliches Tag.

**Anleitung für IG-Autoren: [Container und Publisher aktualisieren](https://github.com/Gefyra/IGPublisherDevContainer#-container-und-publisher-aktualisieren)** im Template-README.

## Bestehendes Projekt migrieren

Projekte, die vor dieser Umstellung aus dem [Template](https://github.com/Gefyra/IGPublisherDevContainer) entstanden sind, tragen die Konfiguration noch selbst. Sie funktionieren nach einem Rebuild weiter — mit **einer Ausnahme**.

### Erforderlich: ein Task

Der Task „Update IG Publisher" ruft in der alten `tasks.json` direkt `./_updatePublisher.sh -y`. Das schreibt per `curl -o` durch den Symlink ins root-eigene `/opt` und scheitert mit `curl: (23) Failure writing output to destination`. Es geht nichts verloren, der Task funktioniert aber erst wieder nach dieser Änderung in `.vscode/tasks.json`:

```json
{
  "label": "Update IG Publisher",
  "type": "shell",
  "command": "ig-update-publisher"
}
```

`post-create.sh` erkennt den Zustand und weist beim Container-Create darauf hin.

### Optional: aufräumen

Wenn du ohnehin im Repo bist, kannst du die restliche Duplizierung entfernen. Der Nutzen: künftige Verbesserungen an dieser Logik erreichen das Projekt allein durch einen Rebuild.

- `.devcontainer/devcontainer.json` auf die Form oben eindampfen — `remoteUser`, `forwardPorts`, `postCreateCommand`, `postStartCommand` und die Extension-Liste kommen aus dem Image.
- Die Tasks „Git: Commit Changes", „Download: IG Package" und „Download: JSON Resources" auf `ig-commit "${input:commitMessage}"`, `ig-package` und `ig-json-resources` umstellen.

`.vscode/tasks.json` selbst muss im Repo bleiben — VS Code liest sie aus dem Workspace, sie kann nicht aus dem Image kommen. Durch die Wrapper enthält sie danach aber nur noch Kommandonamen und muss nicht erneut angefasst werden, wenn sich die Logik ändert.

## Am Image entwickeln

```bash
docker build -f .devcontainer/Dockerfile -t igpub-dc-test:local .

# Metadata-Label prüfen
docker inspect igpub-dc-test:local \
  --format '{{index .Config.Labels "devcontainer.metadata"}}' | python3 -m json.tool

# Lifecycle-Skripte in einem simulierten Workspace
docker run --rm igpub-dc-test:local bash -c '
  mkdir -p /tmp/ws && cd /tmp/ws && touch ig.ini
  bash /usr/local/share/ig-devcontainer/post-create.sh
  bash /usr/local/share/ig-devcontainer/post-start.sh'
```

Die Skripte liegen unter `.devcontainer/scripts/` und landen im Image unter `/usr/local/share/ig-devcontainer/`; die vier `ig-*`-Wrapper werden zusätzlich nach `/usr/local/bin/` verlinkt. Sie erwarten das Arbeitsverzeichnis im Workspace-Ordner — so rufen Devcontainer-Lifecycle-Kommandos und VS-Code-Tasks sie beide auf.

Ein Push auf `main`, der `.devcontainer/**` berührt, baut und veröffentlicht das Image. Zusätzlich löst ein neues Basis-Image den Build über `repository_dispatch` aus.
