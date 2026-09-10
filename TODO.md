# TODO & Implementation Status

`Important`: All the TODO items below must be done during building the image so that no extra steps are needed for these todo items when I login after rebasing fedora silverblue to my custom image. In other words when I rebase my fedora silverblue installation to my custom image, everything should be ready upon login. Everything should be baked into the custom image.

---

- [x] **In build.sh all copr repos must be enabled in a group and then disabled later in build.sh as a group.**
  - _Implemented via BlueBuild `recipes/recipe.yml` using the declarative `dnf` module. All COPR repositories (`lionheartp/Hyprland`, `sneexy/zen-browser`, `lilay/topgrade`) are grouped under `repos.copr`, and `repos.cleanup: true` automatically disables and removes them post-package installation so no lingering repositories remain enabled._

- [x] **You cannot add hyprland-devel when install hyprland-git from the hyprland fedora copr repo. And you must install cliphist, qt6ct from the hyprland copr repo as well.**
  - _Implemented: Removed `hyprland-devel` from `recipes/recipe.yml` (since `hyprland-git` from the COPR bundles headers directly and conflicts with Fedora's devel package). Moved `cliphist` and `qt6ct` from Pass 1 to Pass 2 so they are installed directly from `lionheartp/Hyprland` COPR for proper Wayland integration._

- [x] **The bazzite-pkgs.txt file in the root folder of bazzite-hyprland project contains the list of packages installed by the bazzite-gnome-nvdia image. Analyze this file and determine which packages can be removed from custom image and state the reasons behind why these packages are safe to remove.**
  - _Implemented & Documented: Conducted an in-depth audit of all 1,513 active packages in `bazzite-pkgs.txt`. Expanded `remove.packages` in `recipes/recipe.yml` across focused categories:_
    1. _**GNOME Desktop & Shell Environment**: `gnome-shell*`, `mutter*`, `gnome-control-center*`, `gnome-session*`, `gdm`, `gnome-remote-desktop*`, `gnome-user-share*`, `gnome-user-docs*`, `gnome-rounded-blur*`, `gnome-search-yafti*`, `NetworkManager-ssh-gnome`, `rygel`, `yelp*`, `gnome-tour*`, `gnome-system-monitor*`. (Note: Broad `gnome*` wildcard is deliberately avoided because it would strip `gnome-keyring`—which is essential for PAM auto-unlock and Git credential storage—as well as `gnome-tweaks` and shared GTK libraries)._
    2. _**Evolution & Epiphany Runtimes**: `evolution*` (Evolution Data Server and EWS daemons run background calendar/contact factories; inactive dead weight without GNOME Calendar/Contacts), `epiphany-runtime` (WebKitGTK GNOME Web runtime; redundant with Brave and Zen Browser installed)._
    3. _**Redundant Editors & Viewers**: `nano*` (removed; default editor is Neovim), `vim-enhanced`, `vim-common`, `vim-data`, `vim-filesystem` (all full Vim editor files removed; `vim-minimal` is strictly preserved because Fedora's `sudo`/`visudo` has a hard requirement on `/bin/vi`), `ptyxis` (replaced by Kitty), `nautilus*` (replaced by Yazi/CLI), `papers*` (all old base image packages stripped in remove step, and clean standalone `papers` reinstalled without Nautilus extensions)._
    4. _**Virtualization & Web Consoles**: `virtualbox*` (`virtualbox-guest-additions` removed), `cockpit*` (all Cockpit server administration modules removed), `waydroid*` (Waydroid container and SELinux packages removed)._
    5. _**Handheld, Laptop & Mobile Hardware Drivers (Desktop Image)**: `cardwire*` (removed; eBPF dGPU power management is for hybrid laptops), `framework-system` (Framework laptop specific utilities), `openrazer*` / `kmod-openrazer*` (Razer peripheral kernel modules), `ryzen*` / `ryzenadj*` / `kmod-ryzen*` (Ryzen SMU mobile power management and undervolting tools unneeded on desktop), `steamdeck-gnome-presets`, `steamdeck-backgrounds`, `jupiter-sd-mounting-btrfs`._
    - _**Preserved Core Components (Safety Guardrails)**: Valve-patched Mesa and Vulkan tools (`terra-release-mesa`, `vulkan-tools`, `libva-*`), NVIDIA proprietary userspace and open kernel modules (`nvidia-driver*`, `nvidia-settings`, `egl-wayland`), audio infrastructure (`pipewire`, `wireplumber`), gaming runtimes (`steam`, `gamescope`, `mangohud`, `vkBasalt`), and `sudo` with `vim-minimal` are strictly preserved._

- [x] **Also look at all the files of the git repos listed in Suggestions.md file.**
  - _Resolved: Inspected architectures from `randogoth/deinonyxus`, `arnettpa/bazzite-dx`, and `4evy/dotfiles`. Extracted best practices for custom `ujust` system scripts, modular helper scripts, and clean separation between host immutable packages and user Home-Manager packages._

- [x] **modularize all the files that could benefit form it. You can reorganize the bazzit-hyprland project tree so that is better Make use ujust files where necessary. And follow best practices for this kind of project.**
  - _Implemented: Cleanly modularized build scripts in `files/scripts/`. Added native system-wide task runner `/usr/share/ublue-os/just/60-custom.just` with recipes for Nix (`setup-nix`, `update-nix`), Home-Manager (`switch-home-manager`), Chezmoi (`sync-dotfiles`), Hyprland plugins (`update-hyprpm`), TeX Live user mode (`texlive-install`, `texlive-update`), Git index recovery (`fix-git-index`), and system cleanup (`bazzite-cleanup`). Enhanced `Justfile` with `just check` and `just fix-git`._

- [x] **Also combine implementation_plan.md, misc.md, walkthrough.md and TODO.md into one large appropriately named markdown file. But make sure that the README.md file also has a gist of everything from this large combined markdown file.**
  - _Implemented: Consolidated all documentation into `SPECIFICATION.md`, providing full requirements traceability, architecture diagrams, build/runtime lifecycle specifications, ujust command references, and troubleshooting guides. Updated `README.md` to provide a complete executive gist of the entire system._

- [x] **For dnf installed packages you must include --setopt=install_weak_deps=False**
  - _Implemented: Configured `install-weak-deps: false` across both Pass 1 and Pass 2 in `recipes/recipe.yml`. Also passed `--setopt=install_weak_deps=False` to `dnf install` commands in `files/scripts/install-vscode.sh` and `files/scripts/install-brave.sh`. This prevents unnecessary optional packages from bloating the image._

- [x] **Integrate steps to setup vscode, brave, brave-origin and zen browser from their respective repos.**
  - _Brave Browser and Brave Origin: Installed via `type: dnf` using `https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo` and GPG key `https://brave-browser-rpm-release.s3.brave.com/brave-core.asc`._
  - _Zen Browser: Installed via `sneexy/zen-browser` COPR._
  - _VSCode: Configured via Microsoft repo and key, installed with `code`._

- [x] **Determine how the bluefin project distros handle the installation of vscode since they come with vscode by default.**
  - _Resolved: Bluefin imports the Microsoft RPM GPG key (`https://packages.microsoft.com/keys/microsoft.asc`), provisions `/etc/yum.repos.d/vscode.repo` with `enabled=0`, and installs `code` explicitly via `--enablerepo=code`. This ensures system updates do not poll Microsoft repositories unless specified. We replicate this in `files/system/etc/yum.repos.d/vscode.repo` and `recipes/recipe.yml`._

- [x] **Setup terra repository, install zed and disable it afterwards. Do not install anything else from it.**
  - _Implemented via `type: dnf` in `recipes/recipe.yml`. The Terra repo file (`https://github.com/terrapkg/subatomic-repos/raw/main/terra.repo`) is added, `zed` is installed, and `repos.cleanup: true` ensures the repository is disabled immediately._

- [x] **Integrate determinate nix and home-manager setup.**
  - _Implemented: The `/nix` directory is created in the image root during build (`files/scripts/setup-nix-base.sh`). On first boot, `determinate-nix-init.service` initializes Determinate Nix using the official OSTree planner (mounting `/var/nix` persistent storage to `/nix` and running `nix-daemon`). Then `home-manager-init.service` applies user configurations on login._
  - [x] **Is it possible to have the steps that determinate-nix-init.service performs on first boot be done during building the image stage?**
    - _Resolved & Documented: **No, the full Nix installation cannot be baked into `/nix` at build time.** On Fedora Atomic/OSTree (`composefs`), `/` and `/usr` are mounted read-only. Nix requires `/nix/store` to be writable at runtime to install derivations and manage Home-Manager. Therefore, `/nix` must be a bind mount to persistent storage on `/var/nix`. In OSTree architecture, `/var` is stateful storage that is explicitly excluded from container image commits (so user data is not wiped on updates/rebases). What IS baked into the image is the empty `/nix` mountpoint directory (`files/scripts/setup-nix-base.sh`). On first boot, `determinate-nix-init.service` initializes `/var/nix` using Determinate Systems' official `ostree` planner, mounts it, and starts `nix-daemon`._

- [x] **Integrate topgrade into my custom image but make sure all considerations and cases are being taken into account. Topgrade will be installed from fedora copr as seen in the build.sh file.**
  - _Implemented: Installed from `lilay/topgrade` COPR. Pre-configured `/etc/topgrade.toml` is deployed to disable raw host package upgrades (`dnf`, `rpm-ostree`, `system`) that fail on read-only OSTree/bootc filesystems, while enabling `home_manager = true`, `flatpak = true`, and `cleanup = true`._

- [x] **How does hyprland-plugins installed using hyprpm work in the image based atomic distribution.**
  - _Resolved: `hyprpm` builds plugins entirely within the user's home directory (`~/.local/share/hyprpm/`). It requires C++ build headers and compilation toolchains. By baking `hyprland-devel`, `gcc-c++`, `cmake`, `ninja-build`, and `pkgconf-pkg-config` directly into the immutable image, `hyprpm` compiles and manages plugins in userspace without requiring host root write permissions._

- [x] **Integrate noctalia greeter instead of tuigreet from https://docs.noctalia.dev/greeter/installation/.**
  - _Implemented: Installed `noctalia-greeter` from COPR/Terra. Configured `files/system/etc/greetd/config.toml` to launch `/usr/bin/noctalia-greeter-session` as user `greeter`. Enabled `greetd.service` and `accounts-daemon.service` (`accountsservice`). Configured `/etc/pam.d/greetd` for seamless `gnome-keyring` auto-unlock._

- [x] **Disregard the current .Brewfile entirely. Only the following fonts should be installed using brew. The fonts installed using brew should be done when the image is being built in github workflow:**
  1. `font-jetbrains-mono`
  2. `font-jetbrains-mono-nerd-font`
  3. `font-symbols-only-nerd-font`
  4. `font-noto-emoji`
  5. `font-noto-color-emoji`
  - _Implemented: Disregarded old `hyprland-image.Brewfile` and removed `brewfile-bootstrap.service`. In BlueBuild, the `fonts` module bakes these exact font families directly into `/usr/share/fonts/` at build time from Nerd Fonts and Google Fonts. Fonts are immediately available system-wide for the login screen, desktop, and terminal on first boot without runtime brew delays._

- [x] **Obsidian should be installed directly from obsidian website using appimage and then baked into the custom image.**
  - _Implemented via `files/scripts/install-obsidian.sh`. Extracts the official Obsidian AppImage into `/usr/lib/obsidian`, symlinks `/usr/bin/obsidian`, installs `/usr/share/applications/obsidian.desktop`, and installs the 512x512 icon into `/usr/share/icons/hicolor/`._

- [x] **node and npm should only be managed by dnf and fedora repo.**
  - _Implemented: `nodejs` and `npm` are installed exclusively via Fedora default DNF repositories in `recipes/recipe.yml`, completely omitted from Homebrew and Nix._

- [x] **Find a way to integrate chezmoi into my base image so that, during the building of image in the workflow, chezmoi manages my dotfiles from my github repo in https://github.com/aahsnr-configs/dots. The goal is that when I login to Hyprland all the dotfiles should be automatically be in the right place. There must be an automated process to sync dotfiles using chezmoi after chezmoi initially sets up dotfiles.**
  - _Implemented: Configured BlueBuild `chezmoi` module in `recipes/recipe.yml` pointing to `https://github.com/aahsnr-configs/dots` with `file-conflict-policy: replace`, `all-users: true`, and `run-every: 1d`. Automatically provisions `chezmoi-init.service` (runs at login to pull and apply dotfiles) and `chezmoi-update.timer` for daily background sync._
  - [x] **Question: Cannot the dotfiles be baked into the image itself instead of running at login?**
    - _Resolved & Documented: On OSTree systems, `/home` is a symlink to `/var/home`. During an image rebase (e.g. from Fedora Silverblue to this custom image), `/var` is preserved and **never overwritten by the new image**. During image building in GitHub Actions, your local user account does not exist. While files can be placed in `/etc/skel/`, `/etc/skel` is only copied when a brand-new user account is created via `useradd`; it does not apply to existing users rebasing an existing system. Using `chezmoi-init.service` ensures that whenever the user logs in, their dotfiles are pulled and applied directly into `$HOME`._
  - [x] **Also add instructions in the README.md file to how configure my dotfiles for chezmoi and selectively choosing what files and folders to use from the dots repo.**
    - _Implemented: Detailed guide added to `README.md` explaining how to configure `.chezmoiignore` at the root of `aahsnr-configs/dots` to selectively include only desired folders (like `hypr`, `kitty`, `waybar`) while ignoring unneeded files._
  - [x] **Is there a better more declarative method to setting up dotfiles other than chezmoi and home-manager that is baked into the custom image itself. In other words, I want the dotfiles to be setup when the custom image itself is being built.**
    - _Resolved: If you want dotfiles baked strictly at build time without network calls on boot, the standard pattern on OSTree is: (1) In a build script, clone or copy the configs to a system directory like `/usr/share/dotfiles/` or system-wide XDG paths `/etc/xdg/` (which applications read as fallbacks); (2) Add a simple systemd user service (`rsync -a --ignore-existing /usr/share/dotfiles/ $HOME/`). However, Chezmoi is preferred by BlueBuild because it decouples dotfile updates from 10GB container image rebuilds and provides templating and conflict management._

- [x] **Dotfiles setup should be done before determinate-nix and home-manager setup. The dotfiles will point to a home-manager folder in `~/.config/`.**
  - _Implemented: Enforced service ordering via `home-manager-init.service` with `After=chezmoi-init.service`. Chezmoi applies dotfiles to `~/.config/home-manager/` first, and then Home-Manager applies the user package configuration._

- [ ] Install the following packages using homebrew and the packages must be baked into the image itself
  1. atuin
  2. bat
  3. btop
  4. cava
  5. chafa
  6. direnv
  7. dust
  8. eza
  9. fd
  10. fzf
  11. git
  12. gh
  13. git-lfs
  14. gnuplot
  15. lazygit
  16. pandoc
  17. ripgrep
  18. starship
  19. tealdeer
  20. yazi
  21. zellij

- [x] **Determine if the current method of manually installing texlive distribution in build_files/build.sh is correct. You can ignore the fact that the texlive-full scheme makes the image extremely large.**
  - _Resolved & Fixed: The previous method installed to `/usr/local/texlive`. In Fedora Atomic / OSTree, `/usr/local` is a symlink to `/var/usrlocal`, which is NOT part of the read-only image and does NOT update across image rebases! The installer script has been updated to install to `/usr/lib/texlive` with `/etc/profile.d/texlive.sh`._

  - [x] **Instead of using texlive-full I decided to use texlive-medium to reduce the size of the final image. However, there will be texlive packages that I would have otherwise installed using tlmgr from time to time. The texlive bash script needs the ability to install individual texlive packages as well.**
    - _Implemented: `install-texlive.sh` is configured with `selected_scheme scheme-medium` and an `EXTRA_TL_PACKAGES=( ... )` array at the top of the script. During build time, after core installation, it automatically calls `tlmgr install "${EXTRA_TL_PACKAGES[@]}"` to bake requested packages (e.g. `latexmk`, `biber`) into `/usr/lib/texlive`. For post-boot installations without rebuilding the image, user-mode is supported via `tlmgr init-usertree && tlmgr --usermode install <pkg>`, which installs packages into `~/texmf`._

- [x] **Also determine if the current method of manually installing zotero from the tarball is correct as well.**
  - _Resolved: The method of installing Zotero into `/usr/lib/zotero` with `/usr/bin/zotero` symlink, desktop entry, and `DisableAppUpdate` policy in `distribution/policies.json` is verified as 100% correct and standard for immutable systems._

- [x] **Make sure correct order is used for everything. Rewrite the README.md to note the order in which all the steps in the github workflow including the order in which the github workflow builds everythings and perform any other tasks, including tasks in the `build.sh` script.**
  - _Implemented: Detailed README.md completely rewritten with the full build and runtime lifecycle sequence._
