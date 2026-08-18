FROM ghcr.io/gefyra/ig-publisher-with-snapshot-support:latest

# Devcontainer additions on top of the shared IG Publisher image.
# python3: "Serve IG Locally" task (python3 -m http.server)
# zip:     "Download: JSON Resources" task
# fonts:   IG Publisher renders images via java.awt and needs fontconfig
# sudo:    so the image works standalone, without the common-utils feature
RUN apt-get update && apt-get install -y --no-install-recommends \
      bash-completion \
      python3 \
      zip \
      fontconfig fonts-dejavu fonts-liberation \
      sudo \
    && rm -rf /var/lib/apt/lists/*

# Lifecycle scripts and task wrappers. Keeping them in the image rather than in
# each IG repository means a fix ships to every project through a container
# rebuild, instead of being copied into N repositories by hand.
COPY .devcontainer/scripts/ /usr/local/share/ig-devcontainer/
RUN set -eux; \
    chmod 0755 /usr/local/share/ig-devcontainer/*; \
    for c in ig-update-publisher ig-commit ig-package ig-json-resources; do \
      ln -sf "/usr/local/share/ig-devcontainer/$c" "/usr/local/bin/$c"; \
    done

# Devcontainer image metadata (https://containers.dev/implementors/spec/#image-metadata).
# Merged into every consuming devcontainer.json at create time: lifecycle commands
# are collected and all run, forwardPorts is unioned, extensions are merged, and
# remoteUser takes the last value - the project's devcontainer.json wins on conflict.
LABEL devcontainer.metadata='[{ \
  "remoteUser": "runner", \
  "forwardPorts": [8080], \
  "portsAttributes": { "8080": { "label": "IG Preview", "onAutoForward": "notify" } }, \
  "postCreateCommand": "bash /usr/local/share/ig-devcontainer/post-create.sh", \
  "postStartCommand": "bash /usr/local/share/ig-devcontainer/post-start.sh", \
  "customizations": { "vscode": { "extensions": [ \
    "gematikde.codfsh", \
    "fhir-shorthand.vscode-fsh", \
    "yannick-lagger.vscode-fhir-tools", \
    "redhat.vscode-yaml", \
    "esbenp.prettier-vscode", \
    "yzhang.markdown-all-in-one", \
    "streetsidesoftware.code-spell-checker", \
    "mhutchie.git-graph", \
    "peakchen90.open-html-in-browser", \
    "spencerwmiles.vscode-task-buttons" \
  ] } } \
}]'

# Set workdir to match VSCode default mount
WORKDIR /workspaces

# Create unprivileged user
RUN useradd -m runner \
 && mkdir -p /workspaces \
 && chown -R runner:runner /workspaces \
 && chsh -s /bin/bash runner \
 && echo '[ -f /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion' >> /home/runner/.bashrc \
 && echo 'runner ALL=(root) NOPASSWD:ALL' > /etc/sudoers.d/runner \
 && chmod 0440 /etc/sudoers.d/runner
USER runner
