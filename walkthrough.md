# Walkthrough: Implementation of All Pending Tasks & QoL Features

All tasks from [`TODO.md`](file:///home/ahsan/Git/configs/bazzite-hyprland/TODO.md) have been implemented, tested, and validated.

---

## 1. Hyprland COPR Package Adjustments

In [`recipes/recipe.yml`](file:///home/ahsan/Git/configs/bazzite-hyprland/recipes/recipe.yml):
- **Pass 1 (Fedora-Native)**: Removed `cliphist` and `qt6ct`.
- **Pass 2 (COPR & Terra)**:
  - Removed `hyprland-devel` (the `hyprland-git` package from `lionheartp/Hyprland` COPR bundles its own C++ headers; installing Fedora's standard `hyprland-devel` caused conflict).
  - Added `cliphist` and `qt6ct` under `# From lionheartp/Hyprland COPR` so they are installed directly from the Hyprland COPR for optimal Wayland integration.

---

## 2. System-Wide Environment Profile (`00-custom-environment.sh`)

Created [`files/system/etc/profile.d/00-custom-environment.sh`](file:///home/ahsan/Git/configs/bazzite-hyprland/files/system/etc/profile.d/00-custom-environment.sh) with POSIX compliance:
- Configures XDG Base Directory specification variables (`XDG_CONFIG_HOME`, `XDG_DATA_HOME`, etc.).
- Defines default applications: `TERMINAL="kitty"`, `BROWSER="brave"`, `EDITOR="nvim"`, `VISUAL="emacsclient -c -a emacs"`, `PAGER="bat --paging=always --style=plain"`.
- Utilizes `pathprepend()` to safely add user directories to `$PATH`:
  - `~/.bin`
  - `~/.cargo/bin`
  - `~/go/bin`
  - `~/.bun/bin` & `~/.cache/.bun/bin`
  - `~/.local/bin`
  - `~/.config/emacs/bin`
  - `~/.npm-global/bin`
  - `~/.nix-profile/bin` & `/nix/var/nix/profiles/default/bin` (ensuring Home-Manager and Nix binaries are available instantly upon login).

---

## 3. Native `ujust` Task Runner (`60-custom.just`)

Created [`files/system/usr/share/ublue-os/just/60-custom.just`](file:///home/ahsan/Git/configs/bazzite-hyprland/files/system/usr/share/ublue-os/just/60-custom.just) supplying custom system commands for Bazzite's native `ujust` runner:
- `ujust setup-nix`: Verifies or triggers the Determinate Nix installer.
- `ujust update-nix`: Updates Nix channels and flake registries.
- `ujust switch-home-manager`: Re-evaluates and switches `~/.config/home-manager/`.
- `ujust sync-dotfiles`: Pulls and applies latest dotfiles via Chezmoi.
- `ujust update-hyprpm`: Builds/updates Hyprland plugins in userspace.
- `ujust texlive-install <pkg>`: Installs LaTeX packages into `~/texmf` in user mode.
- `ujust texlive-update`: Updates user LaTeX packages.
- `ujust fix-git-index`: Instantly repairs corrupted `.git/index` (`rm -f .git/index && git reset`).
- `ujust bazzite-cleanup`: Cleans Nix garbage, Flatpak runtimes, and system logs.

---

## 4. Developer Workflow Enhancements (`Justfile`)

In [`Justfile`](file:///home/ahsan/Git/configs/bazzite-hyprland/Justfile):
- Added `just check`: Runs syntax checks across all shell scripts and validates the BlueBuild recipe in one command.
- Added `just fix-git`: Quick terminal target for repairing `.git/index`.

---

## 5. Master Specification & Documentation Consolidation

- Created [`SPECIFICATION.md`](file:///home/ahsan/Git/configs/bazzite-hyprland/SPECIFICATION.md), unifying:
  1. System overview and requirements traceability matrix (all 20+ requirements with rationale).
  2. Build-time architecture and execution order.
  3. Runtime first-boot and login lifecycle sequence.
  4. Architectural Q&A (OSTree immutability, Nix on `/var/nix`, Chezmoi selective dotfiles).
  5. Complete `ujust` command reference.
  6. Troubleshooting and maintenance runbooks.
- Updated [`README.md`](file:///home/ahsan/Git/configs/bazzite-hyprland/README.md) to provide an executive summary (gist) of everything in `SPECIFICATION.md`.
- Updated [`TODO.md`](file:///home/ahsan/Git/configs/bazzite-hyprland/TODO.md) to mark all items as complete (`[x]`).

---

## 6. Verification

- `bash -n files/scripts/*.sh` &rarr; All scripts syntax-valid.
- `sh -n files/system/etc/profile.d/00-custom-environment.sh` &rarr; POSIX compliant.
- `just validate` &rarr; `INFO => Recipe recipes/recipe.yml is valid`.
