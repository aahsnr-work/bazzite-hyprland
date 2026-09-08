# Implementation Plan: Address New TODO.md Tasks & Architectural Questions

This implementation plan addresses the newly added, unchecked items in `TODO.md`:
1. Enforcing `--setopt=install_weak_deps=False` across all DNF package installations.
2. Technical assessment of Determinate Nix first-boot vs build-time execution on OSTree/bootc.
3. In-depth analysis of baking dotfiles into the image vs runtime chezmoi/home-manager, and adding selective dotfiles instructions to `README.md`.
4. Adding individual package installation capability via `tlmgr` to `install-texlive.sh` with `scheme-medium`.

---

## User Review Required

> [!IMPORTANT]
> **Key Architectural Decisions to Confirm:**
> 1. **Determinate Nix on OSTree**: We explain why the full Nix store cannot be pre-baked into `/nix` at build time (due to OSTree/composefs read-only root filesystems requiring persistent `/var/nix` storage), but we pre-bake the mount point and binaries.
> 2. **Dotfiles in Image vs. Runtime**: We analyze why OSTree systems do not manage `/home` (since `/home` is a symlink to `/var/home` and `/var` is not modified during image rebases). We show how to configure `.chezmoiignore` for selective dotfiles, and outline an alternative `/etc/skel` or `/usr/share/dotfiles` bake-in approach.
> 3. **TeX Live Package Extensibility**: `install-texlive.sh` will include an `EXTRA_TL_PACKAGES` array for build-time `tlmgr` installations, and support user-mode `tlmgr` at runtime.

---

## Proposed Changes

### Component 1: DNF Weak Dependencies (`--setopt=install_weak_deps=False`)

#### [MODIFY] [recipe.yml](file:///home/ahsan/Git/configs/bazzite-hyprland/recipes/recipe.yml)
- Add `install-weak-deps: false` under `install:` in Pass 1 (Fedora packages).
- Add `install-weak-deps: false` under `install:` in Pass 2 (COPR & Terra packages).

#### [MODIFY] [install-vscode.sh](file:///home/ahsan/Git/configs/bazzite-hyprland/files/scripts/install-vscode.sh)
- Add `--setopt=install_weak_deps=False` to the `dnf install` invocation.

#### [MODIFY] [install-brave.sh](file:///home/ahsan/Git/configs/bazzite-hyprland/files/scripts/install-brave.sh)
- Add `--setopt=install_weak_deps=False` to the `dnf install` invocation.

---

### Component 2: TeX Live Individual Package Installation via `tlmgr`

#### [MODIFY] [install-texlive.sh](file:///home/ahsan/Git/configs/bazzite-hyprland/files/scripts/install-texlive.sh)
- Ensure `selected_scheme scheme-medium` is configured.
- Add an `EXTRA_TL_PACKAGES=( ... )` array at the top of the script so you can declare specific TeX Live packages to bake into `/usr/lib/texlive`.
- After `install-tl` completes, invoke `tlmgr install "${EXTRA_TL_PACKAGES[@]}"` using the newly installed TeX Live binary.
- Document how to use `tlmgr --usermode install` for post-boot user packages.

---

### Component 3: Documentation & Architectural Clarifications

#### [MODIFY] [README.md](file:///home/ahsan/Git/configs/bazzite-hyprland/README.md)
- Add a dedicated section on **Chezmoi Dotfiles Configuration & Selective Filtering**:
  - Explaining `.chezmoiignore` usage in `aahsnr-configs/dots`.
  - Showing how to filter only desired config folders (e.g. `hypr`, `waybar`, `kitty`) while ignoring unneeded folders.
- Add an architectural explanation of **Baking Dotfiles vs. Runtime Chezmoi / Home-Manager on OSTree**:
  - Why `/var/home` is not part of the OSTree image commit.
  - How `/etc/skel` works (only for new users, not rebases).
  - Why the BlueBuild chezmoi module with systemd user service is the recommended pattern.

#### [MODIFY] [TODO.md](file:///home/ahsan/Git/configs/bazzite-hyprland/TODO.md)
- Mark all completed items as `[x]`.
- Provide detailed architectural resolutions for the questions regarding Determinate Nix, baking dotfiles, and TeX Live.

---

## Verification Plan

### Automated Tests
1. Validate BlueBuild recipe schema:
   ```bash
   just validate
   ```
2. Validate syntax of all shell scripts:
   ```bash
   bash -n files/scripts/*.sh
   ```
3. Test dry-run generation:
   ```bash
   just dry-run
   ```

### Manual Verification
- Review updated `README.md` and `TODO.md` sections for clarity and accuracy.
