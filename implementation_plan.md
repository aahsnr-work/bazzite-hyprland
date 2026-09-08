# Migration to BlueBuild & Complete Resolution of TODO.md

Migrate the `bazzite-hyprland` repository from a custom `Containerfile` + `build.sh` build process to **BlueBuild** (`https://blue-build.org/`), a declarative framework for Fedora Atomic / bootc container images. This plan addresses every item in [TODO.md](file:///home/ahsan/Git/configs/bazzite-hyprland/TODO.md) and [misc.md](file:///home/ahsan/Git/configs/bazzite-hyprland/misc.md), ensuring that all packages, fonts, greeter, dotfiles, Nix, and desktop configurations are baked directly into the image for zero post-login setup upon rebasing Fedora Silverblue.

---

## Architecture Overview: The BlueBuild Framework

BlueBuild organizes custom Fedora Atomic builds declaratively:
- **`recipes/recipe.yml`**: Central declarative blueprint defining the base image, image version, metadata, and ordered module execution pipeline.
- **`files/`**: Project assets and configurations:
  - `files/system/`: Files copied directly into the image filesystem root (`/`).
  - `files/scripts/`: Custom modular build scripts invoked via the `script` module.
- **`.github/workflows/build.yml`**: GitHub Actions workflow powered by `blue-build/github-action@v1` with Cosign image signing and `maximize_build_space: true`.

```mermaid
flowchart TD
    subgraph CI["GitHub Actions Runner (ubuntu-24.04)"]
        A[blue-build/github-action@v1] --> B[Parse recipes/recipe.yml]
        B --> C[Base Image: bazzite-gnome-nvidia-open:latest]
        C --> M1["Module: files (copy files/system/ to /)"]
        M1 --> M2["Module: dnf (strip GNOME, enable COPRs, install Hyprland, Brave, Zen, VSCode, Zed)"]
        M2 --> M3["Module: fonts (Nerd Fonts & Google Fonts to /usr/share/fonts/)"]
        M3 --> M4["Module: script (install TeX Live, Zotero, Obsidian AppImage, /nix prep)"]
        M4 --> M5["Module: chezmoi (wire chezmoi-init.service & timer for dotfiles)"]
        M5 --> M6["Module: systemd (enable greetd, accounts-daemon, nix bootstrap; disable gdm)"]
        M6 --> Sign[Cosign Sign & Push to GHCR]
    end

    subgraph Client["Fedora Silverblue Client (First Boot & Login)"]
        Boot[Rebase & First Boot] --> Greetd[greetd launches Noctalia Greeter]
        Greetd --> Login[User Logs In]
        Login --> Chezmoi[chezmoi-init.service applies aahsnr-configs/dots]
        Chezmoi --> Nix[Determinate Nix Daemon ready]
        Nix --> HM[home-manager-init.service executes 'home-manager switch']
        HM --> Ready[Hyprland Environment 100% Ready]
    end
```

---

## User Review Required

> [!IMPORTANT]
> **1. TeX Live Installation Path Correction**:
> In the existing `build_files/build.sh`, TeX Live was installed into `/usr/local/texlive`. On Fedora Atomic / OSTree / bootc, `/usr/local` is a symlink to `/var/usrlocal`. Content written into `/var` during container build is only seeded once upon initial install and is **not updated across subsequent image rebases**. Furthermore, BlueBuild's `files` module explicitly forbids writing to `/usr/local`.
> **Proposed Fix**: TeX Live is installed into `/usr/lib/texlive` (or `/usr/share/texlive`), with `/etc/profile.d/texlive.sh` exporting PATH and MANPATH. This ensures TeX Live is truly immutable, versioned with the image, and correctly preserved across rebases.

> [!IMPORTANT]
> **2. Font Installation (Replacing Homebrew with Build-time Baking)**:
> `TODO.md` requests that only the 5 specified fonts be installed using brew during the GitHub workflow, disregarding the old `.Brewfile`.
> In BlueBuild, the first-class `fonts` module bakes fonts into `/usr/share/fonts/` at build time directly from Nerd Fonts and Google Fonts:
> - `JetBrainsMono` (Nerd Font)
> - `NerdFontsSymbolsOnly` (Nerd Font)
> - `JetBrains Mono` (Google Font)
> - `Noto Emoji` (Google Font)
> - `Noto Color Emoji` (Google Font)
> This eliminates the need for Homebrew at build time for fonts and guarantees fonts are immediately available system-wide (login screen, TTY, Wayland, and all users) with zero runtime delays.

> [!NOTE]
> **3. Runner Operating System (`misc.md`)**:
> GitHub Actions hosted runners only support Ubuntu, macOS, and Windows. There is no hosted `runs-on: fedora` VM provided by GitHub. Using `runs-on: ubuntu-24.04` with `blue-build/github-action@v1` is the official, supported BlueBuild pattern.

---

## Comprehensive Item-by-Item Breakdown of TODO.md

| Item | Requirement | Technical Solution in BlueBuild |
| :--- | :--- | :--- |
| **1** | COPR repos enabled as a group and disabled later | Configured in `recipes/recipe.yml` using `type: dnf` with `repos.copr` and `repos.cleanup: true`. All COPRs are enabled atomically for package installation and cleaned up immediately after. |
| **2** | Setup VSCode, Brave, Brave-Origin, Zen Browser | Configured via `type: dnf`: Brave repo file (`brave-browser.repo`) + key (`brave-core.asc`); Zen Browser via `sneexy/zen-browser` COPR; VSCode via Microsoft repo (`https://packages.microsoft.com/yumrepos/vscode`) and GPG key with `enabled=0` / `cleanup: true` matching Bluefin. |
| **3** | Bluefin VSCode pattern analysis | Bluefin imports the Microsoft GPG key, installs `/etc/yum.repos.d/vscode.repo` with `enabled=0`, and installs `code` with `--enablerepo=code`. Replicated in BlueBuild. |
| **4** | Terra repository for Zed only | Configured in `type: dnf`: adds Terra repo URL, installs `zed`, and automatically removes/disables the Terra repo via `repos.cleanup: true`. |
| **5 & 13** | Determinate Nix & Home-Manager setup | `/nix` mountpoint directory pre-created in root image. `determinate-nix-init.service` sets up the OSTree planner at first boot (bind-mounting `/var/nix` to `/nix`). `home-manager-init.service` runs after `chezmoi-init.service` on login. |
| **6** | Topgrade integration for Atomic Fedora | Installed via `lilay/topgrade` COPR. Ships `/etc/topgrade.toml` tailored for Atomic Fedora: disables raw `dnf` / `rpm-ostree` commands to prevent immutability clashes, enables `home_manager` and `flatpak`, and sets `cleanup = true`. |
| **7** | `hyprpm` on Atomic distribution analysis | `hyprpm` builds plugins in user-space (`~/.local/share/hyprpm/`). It requires C++ build headers and tools. Baking `hyprland-devel`, `gcc-c++`, `cmake`, `ninja-build`, and `pkgconf-pkg-config` into the image enables `hyprpm` to compile plugins in user space with zero host root modifications. |
| **8** | Noctalia Greeter instead of tuigreet | Installed from `lionheartp/Hyprland` COPR or Terra. Configured in `files/system/etc/greetd/config.toml` with `command = "/usr/bin/noctalia-greeter-session"` and `user = "greeter"`. `greetd.service` and `accounts-daemon.service` enabled. |
| **9** | Fonts (disregard .Brewfile, install 5 fonts) | Disregard old `hyprland-image.Brewfile` and remove `brewfile-bootstrap.service`. Install all 5 fonts via BlueBuild's `fonts` module into `/usr/share/fonts/`. |
| **10** | Obsidian AppImage baked into image | Helper script downloads latest Obsidian AppImage, extracts it (`--appimage-extract`) into `/usr/lib/obsidian`, symlinks `/usr/bin/obsidian`, and installs desktop file and icons into `/usr/share/`. |
| **11** | Node and npm managed exclusively by Fedora DNF | Installed via Fedora default DNF repositories; excluded from Homebrew and Nix. |
| **12** | Chezmoi dotfiles automation | Configured via BlueBuild `type: chezmoi` targeting `https://github.com/aahsnr-configs/dots` with `file-conflict-policy: replace` and `all-users: true`. Configures `chezmoi-init.service` (initial pull at login) and `chezmoi-update.timer` (daily sync). |
| **13 & 14** | Dotfiles before Nix/Home-Manager; HM packages | Execution sequence enforced: Chezmoi pulls `~/.config/home-manager/` -> Home-Manager switches packages (atuin, bat, btop, cava, chafa, direnv, dust, eza, fd, fzf, git, gh, git-lfs, gnuplot, lazygit, pandoc, ripgrep, starship, tealdeer, tmux, yazi, zellij, zsh). Host direnv kept. |
| **15** | TeX Live manual install analysis | Existing `/usr/local/texlive` path is flawed on OSTree because `/usr/local` points to `/var/usrlocal`. Corrected to `/usr/lib/texlive` with `/etc/profile.d/texlive.sh`. |
| **16** | Zotero manual install analysis | Existing `/usr/lib/zotero` + `/usr/bin/zotero` + `policies.json` disabling auto-updates is verified as 100% correct. Kept and modularized. |
| **Order** | Rewrite README.md | Document build sequence, runtime lifecycle, directory layout, and rebase commands. |

---

## Proposed Changes

### 1. BlueBuild Recipe Configuration

#### [NEW] [recipe.yml](file:///home/ahsan/Git/configs/bazzite-hyprland/recipes/recipe.yml)
- Declares schema: `# yaml-language-server: $schema=https://schema.blue-build.org/recipe-v1.json`
- Base Image: `ghcr.io/ublue-os/bazzite-gnome-nvidia-open`, version: `latest`
- Modules pipeline:
  1. `type: files`: Copy `files/system/` to `/`.
  2. `type: dnf`:
     - `remove`: Strips GNOME Shell, GDM, Mutter, Nautilus, Ptyxis, etc.
     - `repos`: Grouped COPR repos (`lionheartp/Hyprland`, `sneexy/zen-browser`, `lilay/topgrade`), Brave repo + key, Microsoft key, Terra repo URL. `cleanup: true`.
     - `install`: Hyprland, Noctalia greeter, Brave, Brave Origin, Zen Browser, VSCode, Zed, Node.js, npm, direnv, Hyprland build dependencies (`hyprland-devel`, `gcc-c++`, `cmake`, `ninja-build`, `pkgconf-pkg-config`), and Fedora desktop/audio utilities.
  3. `type: fonts`: Installs JetBrainsMono, NerdFontsSymbolsOnly, JetBrains Mono, Noto Emoji, and Noto Color Emoji.
  4. `type: script`: Runs `install-texlive.sh`, `install-zotero.sh`, `install-obsidian.sh`, and `setup-nix-base.sh`.
  5. `type: chezmoi`: Points to `https://github.com/aahsnr-configs/dots`, `file-conflict-policy: replace`, `all-users: true`.
  6. `type: systemd`: Enables `greetd.service`, `accounts-daemon.service`, `determinate-nix-init.service`; disables `gdm.service`.

---

### 2. Filesystem Overlay & System Configurations

#### [NEW] [config.toml](file:///home/ahsan/Git/configs/bazzite-hyprland/files/system/etc/greetd/config.toml)
- Replaces `tuigreet` with Noctalia Greeter:
  ```toml
  [terminal]
  vt = 1

  [default_session]
  command = "/usr/bin/noctalia-greeter-session"
  user = "greeter"
  ```

#### [NEW] [greetd](file:///home/ahsan/Git/configs/bazzite-hyprland/files/system/etc/pam.d/greetd)
- Configures PAM stack with `pam_gnome_keyring.so` auto-unlock for seamless credential access upon login.

#### [NEW] [topgrade.toml](file:///home/ahsan/Git/configs/bazzite-hyprland/files/system/etc/topgrade.toml)
- Tailored for Atomic Fedora / OSTree: disables raw host package upgrades (`dnf`, `system`), configures `home_manager = true`, `flatpak = true`, and `cleanup = true`.

#### [NEW] [determinate-nix-init.service](file:///home/ahsan/Git/configs/bazzite-hyprland/files/system/usr/lib/systemd/system/determinate-nix-init.service)
- Systemd system unit that initializes the Determinate Nix installer with the OSTree planner at first boot (creating `/var/nix`, binding to `/nix`, enabling the daemon), gated by `ConditionPathExists=!/nix/receipt.json`.

#### [NEW] [home-manager-init.service](file:///home/ahsan/Git/configs/bazzite-hyprland/files/system/usr/lib/systemd/user/home-manager-init.service)
- Systemd user unit configured with `After=chezmoi-init.service`. Triggers `nix run home-manager -- switch` on first login after chezmoi has deployed `~/.config/home-manager/`.

---

### 3. Build Scripts (`files/scripts/`)

#### [NEW] [install-texlive.sh](file:///home/ahsan/Git/configs/bazzite-hyprland/files/scripts/install-texlive.sh)
- Downloads `install-tl-unx.tar.gz`, scripts non-interactive install to `/usr/lib/texlive`, and writes `/etc/profile.d/texlive.sh`.

#### [NEW] [install-zotero.sh](file:///home/ahsan/Git/configs/bazzite-hyprland/files/scripts/install-zotero.sh)
- Downloads official Zotero tarball to `/usr/lib/zotero`, symlinks `/usr/bin/zotero`, configures `DisableAppUpdate` policy, and copies `.desktop` entry.

#### [NEW] [install-obsidian.sh](file:///home/ahsan/Git/configs/bazzite-hyprland/files/scripts/install-obsidian.sh)
- Fetches the latest Obsidian AppImage from GitHub releases, extracts squashfs to `/usr/lib/obsidian`, symlinks `/usr/bin/obsidian`, and integrates desktop file and icon into `/usr/share/`.

#### [NEW] [setup-nix-base.sh](file:///home/ahsan/Git/configs/bazzite-hyprland/files/scripts/setup-nix-base.sh)
- Creates the `/nix` directory mountpoint in `/` at image build time so it exists on the read-only root filesystem at boot.

---

### 4. CI Workflow & Documentation

#### [MODIFY] [build.yml](file:///home/ahsan/Git/configs/bazzite-hyprland/.github/workflows/build.yml)
- Refactors the workflow to use `blue-build/github-action@v1`.
- Targets `recipes/recipe.yml`, enables `maximize_build_space: true`, and configures Cosign signing using `${{ secrets.SIGNING_SECRET }}`.

#### [MODIFY] [misc.md](file:///home/ahsan/Git/configs/bazzite-hyprland/misc.md)
- Answers the CI runner question with comprehensive technical rationale.

#### [MODIFY] [Justfile](file:///home/ahsan/Git/configs/bazzite-hyprland/Justfile)
- Updates Just commands to interface with BlueBuild CLI (`bluebuild build recipes/recipe.yml`) for local testing.

#### [MODIFY] [README.md](file:///home/ahsan/Git/configs/bazzite-hyprland/README.md)
- Complete rewrite documenting:
  1. Build workflow order in GitHub Actions.
  2. Runtime startup & login lifecycle (`greetd` -> Noctalia -> `chezmoi` -> Determinate Nix -> Home-Manager).
  3. Rebase instructions (`rpm-ostree rebase ostree-unverified-registry:ghcr.io/...`).
  4. Maintenance and updates guide.

#### [DELETE] Obsolete files
- Remove old [Containerfile](file:///home/ahsan/Git/configs/bazzite-hyprland/Containerfile), [build_files/build.sh](file:///home/ahsan/Git/configs/bazzite-hyprland/build_files/build.sh), and old `system_files/` directory (fully replaced by `files/system/`).

---

## Verification Plan

### Automated Build Verification
1. **GitHub Actions Workflow Simulation & Syntax Check**:
   - Validate `recipes/recipe.yml` structure against the BlueBuild JSON schema (`https://schema.blue-build.org/recipe-v1.json`).
   - Validate shell scripts in `files/scripts/` with `bash -n` to verify syntactic correctness.
   - Verify all YAML syntax with Python YAML parser.

### Manual Verification Steps (Post-Rebase by User)
1. **First Boot & Greeter**:
   - System boots into Noctalia Greeter graphical login screen (powered by `greetd`).
   - Login authenticates and unlocks GNOME Keyring.
2. **First Login Automation**:
   - Verify `chezmoi-init.service` executes and clones `https://github.com/aahsnr-configs/dots`.
   - Verify `systemctl status determinate-nix-init.service` reports successful Nix store initialization.
   - Verify `home-manager-init.service` applies the home configuration.
3. **Application & Font Verification**:
   - Run `which code brave-browser brave-origin zen-browser zed obsidian zotero xelatex topgrade`.
   - Verify fonts: `fc-list : family | grep -E 'JetBrains|Noto'` returns all 5 installed font families.
   - Run `hyprpm list` to confirm `hyprpm` functions with baked headers.
