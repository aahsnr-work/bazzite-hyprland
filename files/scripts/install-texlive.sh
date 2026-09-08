#!/usr/bin/env bash
set -euo pipefail

echo "=== Installing TeX Live (scheme-full) to /usr/lib/texlive ==="
TEXLIVE_INSTALL_DIR="/usr/lib/texlive"
mkdir -p "${TEXLIVE_INSTALL_DIR}"

TEXLIVE_TMP="$(mktemp -d)"
trap 'rm -rf "${TEXLIVE_TMP}"' EXIT

if curl -fsSL https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz -o "${TEXLIVE_TMP}/install-tl-unx.tar.gz"; then
  tar -xzf "${TEXLIVE_TMP}/install-tl-unx.tar.gz" -C "${TEXLIVE_TMP}"
  cat >"${TEXLIVE_TMP}/texlive.profile" <<EOF
selected_scheme scheme-full
TEXDIR ${TEXLIVE_INSTALL_DIR}
TEXMFLOCAL ${TEXLIVE_INSTALL_DIR}/texmf-local
TEXMFSYSVAR ${TEXLIVE_INSTALL_DIR}/texmf-var
TEXMFSYSCONFIG ${TEXLIVE_INSTALL_DIR}/texmf-config
instopt_adjustpath 0
tlpdbopt_autobackup 0
tlpdbopt_install_docfiles 1
tlpdbopt_install_srcfiles 0
EOF
  "${TEXLIVE_TMP}"/install-tl-*/install-tl \
    -profile "${TEXLIVE_TMP}/texlive.profile" \
    -no-interaction || echo "WARNING: install-tl exited non-zero" >&2

  TEXLIVE_BINDIR="$(find "${TEXLIVE_INSTALL_DIR}" -maxdepth 3 -type d -name 'x86_64-linux' | head -n1)"
  if [ -n "${TEXLIVE_BINDIR}" ]; then
    install -d /etc/profile.d
    cat >/etc/profile.d/texlive.sh <<EOF
export PATH="${TEXLIVE_BINDIR}:\$PATH"
export MANPATH="${TEXLIVE_INSTALL_DIR}/texmf-dist/doc/man:\${MANPATH:-}"
export INFOPATH="${TEXLIVE_INSTALL_DIR}/texmf-dist/doc/info:\${INFOPATH:-}"
EOF
    chmod 644 /etc/profile.d/texlive.sh
    echo "TeX Live successfully installed to ${TEXLIVE_INSTALL_DIR}"
  else
    echo "WARNING: Could not locate TeX Live bin directory." >&2
  fi
else
  echo "WARNING: Could not download install-tl-unx.tar.gz from CTAN" >&2
fi
