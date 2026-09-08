That didn't hit. I have enough solid info already from repo pages themselves. Let me check the arnettpa/bazzite-dx and the 4evy/dotfiles repos more closely, plus look for a couple more candidates via GitHub code search-style query.I have enough good, current results now. Here's what I found — real personal repos (not orgs/docs) actively combining BlueBuild with Nix/home-manager, current as of early September 2026:

## Repos baking Nix/home-manager directly into a BlueBuild recipe

**1. [randogoth/deinonyxus](https://github.com/randogoth/deinonyxus)** — the clearest match.

- "A personal spin of the UBlue Bluefin DX image with the Lix flavored Nix package manager baked in."
- Generated from `blue-build/template`, with a `recipes/recipe.yml`, a `modules/` folder, and `files/` for custom scripts.
- Tags itself with `nix`, `lix`, `home-manager`, `bluebuild`, `bluefin`, `ublue-custom-image`.
- Ships `just` recipes like `upgrade-nix` (upgrades Lix via the user profile, working around the immutable `/nix/store` lowerdir) and `install-nix-software-center`.
- Base image: `ghcr.io/ublue-os/bluefin-dx:latest` with Cockpit/Docker/Firefox/VS Code stripped and `syncthing`, `uv`, `vscodium`, `waydroid` added instead.
- Last updated Jan 27, 2026 — still active this cycle, 5 stars, Apache-2.0.

**2. [arnettpa/bazzite-dx](https://github.com/arnettpa/bazzite-dx)** — Bazzite + Bluefin/Aurora DX capabilities via BlueBuild.

- README explicitly documents: "To setup nix via determinate nix-installer, run `ujust nix-setup`" — so Nix isn't baked as an image layer but is installed via a `ujust` recipe wired into the build/first-boot flow using the **Determinate Nix Installer**.
- Also ships a `setup-virtualization.sh` script and VFIO/kernel-arg setup, and instructions for generating an offline ISO.

**3. [Sparkrai/bazzite-dx](https://github.com/Sparkrai/bazzite-dx)** — a differently-maintained, similarly-named "Custom image based on Bazzite with added Bluefin/Aurora DX capabilities," tagged `bluebuild`/`ublue-custom-image`. Worth a look for a second take on the same pattern (last updated Mar 2025, so more dormant).

## Adjacent repo (dotfiles, not the image build itself, but pairs a BlueBuild-based OS with home-manager)

**4. [4evy/dotfiles](https://github.com/4evy/dotfiles)** — "Personal workstation config for Spectrum/Bluefin, NixOS, and macOS, with shared chezmoi dotfiles." Tagged `bluebuild`, `nixos-configuration`, `bootc`, `nix-flake`, `sops-nix`, `universal-blue`. This one runs home-manager/chezmoi _on top of_ a Bluefin (BlueBuild-built) host rather than baking Nix into the recipe itself — still very current (updated Sep 7, 2026).

## Why the pool is small

BlueBuild's own modules ecosystem doesn't ship an official Nix/home-manager module — the `blue-build/modules` repo (the standard module library) has no first-party Nix integration — so anyone doing this is hand-rolling it via a custom module or a `type: script`/`ujust` step that runs the Determinate Nix Installer or Lix, then optionally layers home-manager for dotfiles management. That's exactly the pattern in deinonyxus and bazzite-dx above. If you want, I can pull the actual `recipe.yml`/module source from deinonyxus or arnettpa's repo so you can see the exact YAML/script wiring.
