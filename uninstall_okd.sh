#!/usr/bin/env bash
set -euo pipefail

BIN_DIR="/opt/bin"
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
# 2. Limpiar PATH en .bashrc si contiene /opt/bin
# ----------------------------------------------

echo "[2/5] Limpiando PATH en ~/.bashrc..."

if grep -q "export PATH=/opt/bin" "$BASHRC"; then
    sed -i '/\/opt\/bin/d' "$BASHRC"
    echo "  ✔ Entrada eliminada de .bashrc"
else
    echo "  - No había entrada de /opt/bin en PATH"
fi

# ----------------------------------------------
# 3. Limpiar logs y estado oculto del installer
# ----------------------------------------------

echo "[3/5] Eliminando logs y estado de openshift-install..."

rm -f .openshift_install*.log      2>/dev/null || true
rm -f .openshift_install_state.json* 2>/dev/null || true
rm -f .openshift_install.lock*     2>/dev/null || true

echo "  ✔ Estado oculto eliminado"

# ----------------------------------------------
# 4. Limpiar cache global del instalador
# ----------------------------------------------

echo "[4/5] Eliminando cache de openshift-install..."

rm -rf ~/.cache/openshift-install 2>/dev/null || true
echo "  ✔ Cache eliminada"

# ----------------------------------------------
# 5. Limpieza final opcional (no destruye cluster)
# ----------------------------------------------

echo "[5/5] Limpieza completa."

echo "=============================================="
echo "   OKD DESINSTALADO DEL HOST."
echo "   Puedes reinstalar con ./install_okd_tools.sh"
echo "=============================================="
