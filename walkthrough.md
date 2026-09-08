# Walkthrough: Implementation of New TODO.md Tasks & Architecture Solutions

All new unchecked tasks from `TODO.md` have been executed, integrated into the repository, and verified.

---

## 1. DNF Weak Dependencies Disabled (`--setopt=install_weak_deps=False`)

* **[`recipes/recipe.yml`](file:///home/ahsan/Git/configs/bazzite-hyprland/recipes/recipe.yml)**:
  * Added `install-weak-deps: false` under `install:` in Pass 1 (Fedora-native packages).
  * Added `install-weak-deps: false` under `install:` in Pass 2 (COPR & Terra packages).
* **[`files/scripts/install-vscode.sh`](file:///home/ahsan/Git/configs/bazzite-hyprland/files/scripts/install-vscode.sh)**:
  * Added `--setopt=install_weak_deps=False` to the `dnf install` command.
* **[`files/scripts/install-brave.sh`](file:///home/ahsan/Git/configs/bazzite-hyprland/files/scripts/install-brave.sh)**:
  * Added `--setopt=install_weak_deps=False` to the `dnf install` command.

This prevents DNF from installing hundreds of optional recommended packages, keeping the image lean and preventing unexpected dependencies.

---

## 2. Determinate Nix on OSTree: First-Boot vs. Build-Time

* **Question Answered**: *Can the steps that `determinate-nix-init.service` performs on first boot be done during the container build stage?*
* **Resolution**:
  * **No, the full installation cannot be baked into `/nix` at build time**.
  * On Fedora Atomic / bootc with `composefs`, `/` and `/usr` are mounted strictly **read-only**.
  * Nix requires a **writable `/nix/store`** to install packages and evaluate flakes at runtime.
  * Therefore, `/nix` must be a bind mount to persistent, writable host storage in `/var/nix`.
  * In OSTree architecture, `/var` is machine-local state that is **not included in container image commits** (so local user data is not wiped when rebasing/updating).
  * **What is baked into the image**: The empty `/nix` directory mountpoint (`files/scripts/setup-nix-base.sh`).
  * On first boot, `determinate-nix-init.service` runs the Determinate Nix installer with the official `ostree` planner, sets up `/var/nix`, creates the mount, and starts `nix-daemon`.

---

## 3. Dotfiles: Chezmoi Selective Configuration vs. Image Baking

* **Question Answered**: *Can dotfiles be baked into the image itself instead of running at login? Is there a more declarative method?*
* **Resolution**:
  * On OSTree systems, `/home` is a symlink to `/var/home`. During an image rebase (e.g. from Fedora Silverblue to this image), `/var` is preserved and **never overwritten by the new image**.
  * During image building on GitHub Actions, your local user account does not exist.
  * Files placed in `/etc/skel/` only copy when creating a **brand-new user** via `useradd`; they are ignored for existing users rebasing an existing installation.
  * System-wide fallbacks can be placed in `/etc/xdg/`, but personal user dotfiles are designed to live in `$HOME`.
  * **Why Chezmoi is the Recommended BlueBuild Standard**: It decouples dotfile updates from 10GB container image rebuilds and provides templating and automated synchronization.
* **Selective Filtering Documentation Added to [`README.md`](file:///home/ahsan/Git/configs/bazzite-hyprland/README.md#how-to-selectively-filter-files-and-folders-in-chezmoi)**:
  * Documented how to add `.chezmoiignore` to the root of `https://github.com/aahsnr-configs/dots` to selectively choose which folders to apply:
    ```text
    # Ignore unwanted tools or environments
    .config/sway/
    .config/i3/
    unwanted-tool/
    ```

---

## 4. TeX Live: `scheme-medium` & Individual Package Extensibility (`tlmgr`)

* **[`files/scripts/install-texlive.sh`](file:///home/ahsan/Git/configs/bazzite-hyprland/files/scripts/install-texlive.sh)**:
  * Updated configuration to use `selected_scheme scheme-medium` to keep the base image size manageable.
  * Added an `EXTRA_TL_PACKAGES=( ... )` array at the top of the script. Any packages listed (e.g. `latexmk`, `biber`) are automatically installed into `/usr/lib/texlive` using `tlmgr install` at build time.
  * Documented how to install packages at runtime without rebuilding the image using user-mode:
    ```bash
    tlmgr init-usertree
    tlmgr --usermode install <package-name>
    ```
    This installs packages to `~/texmf`, fully preserved across image updates.

---

## 5. Verification Results

* **Shell Script Syntax**: Passed (`bash -n files/scripts/*.sh` completed with exit code 0).
* **BlueBuild Recipe Schema**: Passed (`just validate` -> `INFO => Recipe recipes/recipe.yml is valid`).
* **Status**: All items in [`TODO.md`](file:///home/ahsan/Git/configs/bazzite-hyprland/TODO.md) are now marked complete (`[x]`).
