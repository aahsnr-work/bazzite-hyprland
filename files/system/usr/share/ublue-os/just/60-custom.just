# Custom ujust recipes for bazzite-hyprland
# Installed system-wide to /usr/share/ublue-os/just/60-custom.just

# Display available custom commands for bazzite-hyprland
@custom-help:
    echo "=== bazzite-hyprland custom commands ==="
    echo "  ujust setup-nix            : Verify or re-run Determinate Nix initialization"
    echo "  ujust update-nix           : Update Nix channels and flake registries"
    echo "  ujust switch-home-manager  : Apply ~/.config/home-manager/ configuration"
    echo "  ujust sync-dotfiles        : Pull and apply latest dotfiles via Chezmoi"
    echo "  ujust update-hyprpm        : Update and rebuild Hyprland plugins"
    echo "  ujust texlive-install PKG  : Install LaTeX package into ~/texmf (user mode)"
    echo "  ujust texlive-update       : Update all user-installed LaTeX packages"
    echo "  ujust fix-git-index        : Recover from corrupted/0-byte .git/index"
    echo "  ujust bazzite-cleanup      : Collect Nix garbage and clean Flatpak/system caches"

# Verify or manually trigger Determinate Nix setup
setup-nix:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -f /nix/receipt.json ]; then
        echo "Determinate Nix is already initialized (/nix/receipt.json exists)."
        systemctl status nix-daemon.service --no-pager || true
    else
        echo "Running Determinate Nix installer with ostree planner..."
        curl --proto "=https" --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install ostree --no-confirm
    fi

# Update Nix flake registries and user channels
update-nix:
    #!/usr/bin/env bash
    set -euo pipefail
    [ -f /etc/profile.d/nix.sh ] && . /etc/profile.d/nix.sh
    if command -v nix >/dev/null 2>&1; then
        echo "Updating Nix flake registry..."
        nix registry update || true
        echo "Updating Nix channels..."
        nix-channel --update || true
    else
        echo "Nix is not in PATH. Please run: ujust setup-nix" >&2
        exit 1
    fi

# Re-evaluate and switch Home-Manager configuration from ~/.config/home-manager/
switch-home-manager:
    #!/usr/bin/env bash
    set -euo pipefail
    [ -f /etc/profile.d/nix.sh ] && . /etc/profile.d/nix.sh
    [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ] && . "$HOME/.nix-profile/etc/profile.d/nix.sh"
    if ! command -v nix >/dev/null 2>&1; then
        echo "Nix daemon not detected. Run 'ujust setup-nix' first." >&2
        exit 1
    fi
    if [ -d "$HOME/.config/home-manager" ]; then
        echo "Applying Home-Manager configuration..."
        nix run home-manager -- switch --flake "$HOME/.config/home-manager" || nix run home-manager -- switch
        echo "Home-Manager switch complete."
    else
        echo "No ~/.config/home-manager directory found. Run 'ujust sync-dotfiles' first." >&2
        exit 1
    fi

# Pull and apply latest dotfiles using Chezmoi
sync-dotfiles:
    #!/usr/bin/env bash
    set -euo pipefail
    if command -v chezmoi >/dev/null 2>&1; then
        echo "Applying Chezmoi dotfiles..."
        chezmoi update || chezmoi apply
        echo "Dotfiles synchronized successfully."
    else
        echo "Chezmoi not found in PATH." >&2
        exit 1
    fi

# Rebuild and update Hyprland plugins via hyprpm
update-hyprpm:
    #!/usr/bin/env bash
    set -euo pipefail
    if command -v hyprpm >/dev/null 2>&1; then
        echo "Updating Hyprland plugins..."
        hyprpm update
        hyprpm reload
        echo "Hyprland plugins updated."
    else
        echo "hyprpm command not found. Ensure you are running a Hyprland session." >&2
        exit 1
    fi

# Install a TeX Live package in user mode into ~/texmf
texlive-install package:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! command -v tlmgr >/dev/null 2>&1; then
        [ -f /etc/profile.d/texlive.sh ] && . /etc/profile.d/texlive.sh
    fi
    if command -v tlmgr >/dev/null 2>&1; then
        if [ ! -d "$HOME/texmf" ]; then
            echo "Initializing TeX Live usertree in $HOME/texmf..."
            tlmgr init-usertree
        fi
        echo "Installing TeX Live package '{{package}}' in user mode..."
        tlmgr --usermode install "{{package}}"
        echo "Package '{{package}}' installed successfully into $HOME/texmf."
    else
        echo "tlmgr not found in PATH." >&2
        exit 1
    fi

# Update all user-installed TeX Live packages in ~/texmf
texlive-update:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! command -v tlmgr >/dev/null 2>&1; then
        [ -f /etc/profile.d/texlive.sh ] && . /etc/profile.d/texlive.sh
    fi
    if command -v tlmgr >/dev/null 2>&1; then
        echo "Updating user TeX Live packages in $HOME/texmf..."
        tlmgr --usermode update --all
    else
        echo "tlmgr not found in PATH." >&2
        exit 1
    fi

# Recover from Git index truncation (index file smaller than expected)
fix-git-index:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -d .git ]; then
        echo "Repairing corrupted Git index in current directory..."
        rm -f .git/index
        git reset
        echo "Git index successfully rebuilt from HEAD."
    else
        echo "Current directory is not a Git repository." >&2
        exit 1
    fi

# Reclaim disk space (Nix garbage collection, Flatpak unused runtimes, cache trim)
bazzite-cleanup:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "=== Cleaning up system and user caches ==="
    if command -v nix-collect-garbage >/dev/null 2>&1; then
        echo "Collecting Nix garbage (deleting old derivations)..."
        nix-collect-garbage -d || true
    fi
    if command -v flatpak >/dev/null 2>&1; then
        echo "Uninstalling unused Flatpak runtimes..."
        flatpak uninstall --unused -y || true
    fi
    echo "Trimming journald logs..."
    journalctl --vacuum-time=7d || true
    echo "Cleanup complete!"

