# Implementation Plan: Hyprland COPR Fixes, ujust System Recipes, QoL Enhancements & Master Documentation Consolidation

This comprehensive implementation plan re-evaluates and audits the entire `bazzite-hyprland` project against the latest requirements in `TODO.md`, references from `Suggestions.md` (`randogoth/deinonyxus`, `arnettpa/bazzite-dx`, `4evy/dotfiles`), and Universal Blue / BlueBuild best practices.

---

## User Review Required

> [!IMPORTANT]
> **Key Audited Changes & Quality-of-Life Additions:**
> 1. **Hyprland COPR Alignment**:
>    - Remove `hyprland-devel` from `recipes/recipe.yml` (lionheartp COPR packages headers directly in `hyprland-git`, and Fedora's standard `hyprland-devel` conflicts with it).
>    - Move `cliphist` and `qt6ct` from Pass 1 (Fedora) to Pass 2 (COPR) as required.
> 2. **Native `ujust` System Task Runner (`60-custom.just`)**:
>    - Adds 8+ interactive, user-facing commands to Universal Blue's native `ujust` runner for managing Nix, Home-Manager, Chezmoi, Hyprpm, TeX Live, and system maintenance.
> 3. **Environment Auto-Sourcing (`00-custom-env.sh`)**:
>    - Ensures `$HOME/.nix-profile/bin` and `/nix/var/nix/profiles/default/bin` are always in `$PATH` system-wide for both terminal shells and desktop application launchers.
> 4. **Master Specification Document (`SPECIFICATION.md`)**:
>    - Fully combines `TODO.md`, `implementation_plan.md`, `misc.md`, and `walkthrough.md` into one authoritative master reference, while keeping an executive gist in `README.md`.

---

## Proposed Changes

### Component 1: Hyprland COPR Package Adjustments

#### [MODIFY] [recipe.yml](file:///home/ahsan/Git/configs/bazzite-hyprland/recipes/recipe.yml)
* **Pass 1 (Fedora-native)**:
  - Remove `cliphist` and `qt6ct`.
* **Pass 2 (COPR & Terra)**:
  - Remove `hyprland-devel`.
  - Add `cliphist` and `qt6ct` under `# From lionheartp/Hyprland COPR`.

---

### Component 2: `ujust` System Recipes & Management (Universal Blue Best Practice)

#### [NEW] [60-custom.just](file:///home/ahsan/Git/configs/bazzite-hyprland/files/system/usr/share/ublue-os/just/60-custom.just)
Universal Blue images provide `ujust` as a user-friendly CLI menu. We deploy `/usr/share/ublue-os/just/60-custom.just` with the following recipes:
* **`ujust setup-nix`**: Verifies or re-triggers the Determinate Nix installer (`determinate-nix-init.service`) and displays daemon status.
* **`ujust update-nix`**: Updates Nix channels, flake registries, and runs store verification.
* **`ujust switch-home-manager`**: Re-evaluates and switches `home-manager` from `~/.config/home-manager/`.
* **`ujust sync-dotfiles`**: Executes `chezmoi update` or `chezmoi apply` to pull the latest dotfiles immediately.
* **`ujust update-hyprpm`**: Runs `hyprpm update` to rebuild Hyprland plugins in userspace.
* **`ujust texlive-install-pkg PKG`**: Runs `tlmgr --usermode install <pkg>` to install LaTeX packages into `~/texmf`.
* **`ujust texlive-update`**: Updates all user-installed TeX Live packages.
* **`ujust fix-git-index`**: Automated repair utility that resolves `.git/index: index file smaller than expected` by rebuilding the index from `HEAD`.
* **`ujust bazzite-cleanup`**: Collects Nix garbage (`nix-collect-garbage -d`), cleans Flatpak unused runtimes, and trims local caches.

---

### Component 3: Environment Profile & PATH Integration (QoL Feature)

#### [NEW] [00-custom-env.sh](file:///home/ahsan/Git/configs/bazzite-hyprland/files/system/etc/profile.d/00-custom-env.sh)
Ensures that all 23 CLI tools installed by Home-Manager (`atuin`, `eza`, `fzf`, `starship`, `zellij`, `zsh`, etc.) and Determinate Nix binaries are seamlessly accessible across all shells (bash, zsh) and desktop sessions:
```bash
# Ensure Nix and Home-Manager user profiles are on PATH
if [ -d "$HOME/.nix-profile/bin" ]; then
  case ":$PATH:" in
    *":$HOME/.nix-profile/bin:"*) ;;
    *) export PATH="$HOME/.nix-profile/bin:$PATH" ;;
  esac
fi
```

---

### Component 4: Developer Workflow Enhancements (`Justfile`)

#### [MODIFY] [Justfile](file:///home/ahsan/Git/configs/bazzite-hyprland/Justfile)
* Add `just check`: Runs `bash -n files/scripts/*.sh` and `just validate` in a single command.
* Add `just fix-git`: Quick terminal target for `.git/index` repair.

---

### Component 5: Documentation Consolidation (`SPECIFICATION.md` & `README.md`)

#### [NEW] [SPECIFICATION.md](file:///home/ahsan/Git/configs/bazzite-hyprland/SPECIFICATION.md)
A comprehensive, unified master specification merging:
1. **Section 1: Requirements & Implementation Traceability** (all 20+ requirements from `TODO.md` with in-depth solutions).
2. **Section 2: Architecture & Lifecycle Design** (two-pass DNF, isolated vendor scripts, OSTree immutability rules, Determinate Nix OSTree planner).
3. **Section 3: Desktop Environment & Security** (Hyprland, Noctalia greeter, PAM `gnome-keyring` auto-unlock, `hyprpm` compilation toolchain).
4. **Section 4: User Configuration & Dotfiles** (Chezmoi selective filtering with `.chezmoiignore`, Home-Manager integration, comparison of image baking vs login services).
5. **Section 5: Runtimes & Applications** (TeX Live `scheme-medium` + `tlmgr`, Obsidian AppImage, Zotero with disabled auto-updates, baked fonts).
6. **Section 6: User Management via `ujust`** (complete command reference for `60-custom.just`).
7. **Section 7: Troubleshooting & FAQ** (Git index truncation fix, runner environment limits).

#### [MODIFY] [README.md](file:///home/ahsan/Git/configs/bazzite-hyprland/README.md)
* Provide a concise executive gist covering the complete system architecture, lifecycle sequence, component breakdown, and `ujust` command table.
* Prominently link to `SPECIFICATION.md` as the unified master specification.

#### [MODIFY] [TODO.md](file:///home/ahsan/Git/configs/bazzite-hyprland/TODO.md)
* Mark all new items as complete (`[x]`).

---

## Verification Plan

### Automated Tests
1. **Recipe Schema Validation**:
   ```bash
   just validate
   ```
2. **Shell Script & Justfile Linting**:
   ```bash
   bash -n files/scripts/*.sh
   just check
   ```
3. **Dry-Run Containerfile Compilation**:
   ```bash
   just dry-run
   ```
4. **Git Index & Working Tree Integrity**:
   ```bash
   git status --short
   ```

### Manual Verification
- Verify that `ujust --show` or syntax inspection of `60-custom.just` confirms all tasks are valid just recipes.
- Verify that `SPECIFICATION.md` and `README.md` correctly cross-link and present consistent, unified information.
