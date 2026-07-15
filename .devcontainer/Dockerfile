FROM ghcr.io/gefyra/ig-publisher-with-snapshot-support:latest

# Devcontainer additions on top of the shared IG Publisher image.
RUN apt-get update && apt-get install -y --no-install-recommends \
      bash-completion \
    && rm -rf /var/lib/apt/lists/*

# Set workdir to match VSCode default mount
WORKDIR /workspaces

# Create unprivileged user
RUN useradd -m runner \
 && mkdir -p /workspaces \
 && chown -R runner:runner /workspaces \
 && chsh -s /bin/bash runner \
 && echo '[ -f /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion' >> /home/runner/.bashrc
USER runner
