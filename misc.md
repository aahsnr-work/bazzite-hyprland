# Miscellaneous Questions & Architectural Decisions

- [x] **How does chezmoi selective dotfiles work with the BlueBuild chezmoi module?**

  The BlueBuild `type: chezmoi` module runs `chezmoi init --apply <repository>` on first user login via a systemd user service (`chezmoi-init.service`). It applies **all** files managed by chezmoi in the repository.

  **Selectivity is controlled inside the dots repo (`aahsnr-configs/dots`), not in `bazzite-hyprland`.**

  To selectively include only specific folders/files, add a `.chezmoiignore` file to the root of the dots repo:

  ```
  # .chezmoiignore — patterns of paths to exclude from chezmoi apply
  # Each line is a glob pattern relative to the source directory root.

  # Example: ignore entire folders you don't want applied on this machine
  some-other-app/
  old-configs/

  # Example: ignore specific files
  .config/foo/bar.conf
  ```

  Alternatively, use `chezmoi`'s template system with a `.chezmoi.toml.tmpl` file to conditionally apply config based on hostname or OS:

  ```toml
  # .chezmoi.toml.tmpl
  [data]
    hostname = "{{ .chezmoi.hostname }}"
  ```

  Then in `.chezmoiignore`:

  ```
  {{ if ne .hostname "my-bazzite-machine" }}
  some-folder/
  {{ end }}
  ```

  The `.chezmoiignore` approach is the recommended, simplest way to exclude unwanted dotfiles from the `aahsnr-configs/dots` repo when chezmoi runs on the bazzite image.
