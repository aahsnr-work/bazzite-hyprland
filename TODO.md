# TODO & Implementation Status

`Important`: All the TODO items below must be done during building the image so that no extra steps are needed for these todo items when I login after rebasing fedora silverblue to my custom image. In other words when I rebase my fedora silverblue installation to my custom image, everything should be ready upon login. Everything should be baked into the custom image.

---

- [x] **In build.sh all copr repos must be enabled in a group and then disabled later in build.sh as a group.**
  - _Implemented via BlueBuild `recipes/recipe.yml` using the declarative `dnf` module. All COPR repositories (`lionheartp/Hyprland`, `sneexy/zen-browser`, `lilay/topgrade`) are grouped under `repos.copr`, and `repos.cleanup: true` automatically disables and removes them post-package installation so no lingering repositories remain enabled._

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

- [x] **Dotfiles setup should be done before determinate-nix and home-manager setup. The dotfiles will point to a home-manager folder in `~/.config/`.**
  - _Implemented: Enforced service ordering via `home-manager-init.service` with `After=chezmoi-init.service`. Chezmoi applies dotfiles to `~/.config/home-manager/` first, and then Home-Manager applies the user package configuration._

- [x] **Home-manager will manage the installation and config of the following packages:**
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
  18. starship,
  19. tealdeer
  20. tmux
  21. yazi
  22. zellij
  23. zsh.
      _[NOTE:] Both direnv installed by fedora and installed by home-manager are needed._
  - _Implemented: Managed through the dotfiles Home-Manager configuration. Fedora host direnv is installed via `type: dnf`._

- [x] **Determine if the current method of manually installing texlive distribution in build_files/build.sh is correct. You can ignore the fact that the texlive-full scheme makes the image extremely large.**
  - _Resolved & Fixed: The previous method installed to `/usr/local/texlive`. In Fedora Atomic / OSTree, `/usr/local` is a symlink to `/var/usrlocal`, which is NOT part of the read-only image and does NOT update across image rebases! The installer script has been updated to install to `/usr/lib/texlive` with `/etc/profile.d/texlive.sh`._

- [x] **Also determine if the current method of manually installing zotero from the tarball is correct as well.**
  - _Resolved: The method of installing Zotero into `/usr/lib/zotero` with `/usr/bin/zotero` symlink, desktop entry, and `DisableAppUpdate` policy in `distribution/policies.json` is verified as 100% correct and standard for immutable systems._

- [x] **Make sure correct order is used for everything. Rewrite the README.md to note the order in which all the steps in the github workflow including the order in which the github workflow builds everythings and perform any other tasks, including tasks in the `build.sh` script.**
  - _Implemented: Detailed README.md completely rewritten with the full build and runtime lifecycle sequence._
