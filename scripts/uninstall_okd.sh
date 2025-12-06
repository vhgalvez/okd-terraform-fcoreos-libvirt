#!/usr/bin/env bash

# scripts/uninstall_okd.sh
set -euo pipefail

BIN_DIR="/opt/bin"
TMP_DIR="/tmp/okd-tools"
BASHRC="$HOME/.bashrc"

echo "=============================================="
echo "          DESINSTALADOR OKD / OpenShift"
echo "=============================================="

# ----------------------------------------------
# 1. Eliminar binarios (oc, kubectl, openshift-install)
# ----------------------------------------------

echo "[1/5] Eliminando binarios..."

for bin in oc kubectl openshift-install; do
    if [[ -f "${BIN_DIR}/${bin}" ]]; then
        echo "  - Eliminando ${BIN_DIR}/${bin}"
        sudo rm -f "${BIN_DIR}/${bin}"
    else
        echo "  - ${bin} no existe, saltando."
    fi
done

# ----------------------------------------------
# 2. Limpiar PATH en .bashrc
# ----------------------------------------------

echo "[2/5] Limpiando PATH en ~/.bashrc..."

if grep -q "/opt/bin" "$BASHRC"; then
    sed -i '/\/opt\/bin/d' "$BASHRC"
    echo "  ✔ Entrada eliminada de .bashrc"
else
    echo "  - No había entrada de /opt/bin en PATH"
fi

# ----------------------------------------------
# 3. Eliminar logs y estados del installer
# ----------------------------------------------

echo "[3/5] Eliminando logs ocultos..."

rm -f .openshift_install*.log       2>/dev/null || true
rm -f .openshift_install_state.json* 2>/dev/null || true
rm -f .openshift_install.lock*      2>/dev/null || true

echo "  ✔ Logs eliminados"

# ----------------------------------------------
# 4. Eliminar cache de openshift-install
# ----------------------------------------------

echo "[4/5] Eliminando cache..."

rm -rf ~/.cache/openshift-install 2>/dev/null || true
echo "  ✔ Cache eliminada"

# ----------------------------------------------
# 5. ELIMINAR SOLO /tmp/okd-tools (tu requerimiento)
# ----------------------------------------------

echo "[5/5] Eliminando carpeta temporal ${TMP_DIR}..."
sudo rm -rf "$TMP_DIR"
echo "  ✔ Carpeta temporal eliminada"

echo "=============================================="
echo "   OKD DESINSTALADO COMPLETAMENTE."
echo "=============================================="