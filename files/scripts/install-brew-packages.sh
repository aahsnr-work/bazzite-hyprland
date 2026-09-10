#!/usr/bin/env bash
set -euo pipefail

echo "=== Baking Homebrew Packages into System Image ==="

BREW_PREFIX="/home/linuxbrew/.linuxbrew"
BREW="${BREW_PREFIX}/bin/brew"
BREW_STAGE="/usr/share/homebrew/home/linuxbrew/.linuxbrew"

# The upstream Bazzite base image already bakes Homebrew into /home/linuxbrew/.linuxbrew
# via a multi-stage COPY from ghcr.io/ublue-os/brew. The linuxbrew user (UID 1000) also
# already exists. We just need to install the required packages on top of this.
if [ ! -x "${BREW}" ]; then
  echo "ERROR: Homebrew binary not found at ${BREW}." >&2
  echo "Expected to be provided by the upstream bazzite base image." >&2
  exit 1
fi

# 24 required Homebrew CLI tools to bake into the image
BREW_PACKAGES=(
  atuin
  bat
  btop
  bun
  cava
  chafa
  direnv
  dust
  eza
  fd
  fzf
  git
  gh
  git-lfs
  gnuplot
  lazygit
  pandoc
  pixi
  ripgrep
  starship
  tealdeer
  uv
  yazi
  zellij
)

echo "Installing ${#BREW_PACKAGES[@]} packages as user linuxbrew..."
su -s /bin/bash linuxbrew -c "
  export HOMEBREW_NO_AUTO_UPDATE=1
  export HOMEBREW_NO_INSTALL_CLEANUP=1
  export HOMEBREW_NO_ANALYTICS=1
  export HOMEBREW_CELLAR='${BREW_PREFIX}/Cellar'
  export HOMEBREW_PREFIX='${BREW_PREFIX}'
  export HOMEBREW_REPOSITORY='${BREW_PREFIX}/Homebrew'
  '${BREW}' install ${BREW_PACKAGES[*]}
  '${BREW}' cleanup -s --prune=all
"

# Sync the populated brew prefix to /usr/share/homebrew (which lives under /usr and IS
# deployed by OSTree) so that brew-setup.service can copy the full package set to
# /var/home/linuxbrew/.linuxbrew on first boot without any network access.
echo "Syncing packages to staged image layer at ${BREW_STAGE}..."
mkdir -p "$(dirname "${BREW_STAGE}")"
cp -aT "${BREW_PREFIX}" "${BREW_STAGE}"
chown -R 1000:1000 "/usr/share/homebrew"

echo "=== Homebrew packages successfully baked into the image ==="
