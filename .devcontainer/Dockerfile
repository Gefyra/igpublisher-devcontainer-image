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
