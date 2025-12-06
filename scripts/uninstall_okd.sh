#!/usr/bin/env bash

# scripts/uninstall_okd.sh
set -euo pipefail

BIN_DIR="/opt/bin"
USR_BIN_DIR="/usr/local/bin"
TMP_DIR="/tmp/okd-tools"
PROFILE_D="/etc/profile.d/okd-path.sh"
BASHRC="$HOME/.bashrc"

echo "=============================================="
echo "        DESINSTALADOR COMPLETO DE OKD"
echo "=============================================="

# -----------------------------------------------------
# 1) Eliminar binarios reales en /opt/bin
# -----------------------------------------------------
echo "[1/6] Eliminando binarios en /opt/bin..."

for bin in oc kubectl openshift-install; do
    if [[ -f "${BIN_DIR}/${bin}" ]]; then
        echo "  - Eliminando ${BIN_DIR}/${bin}"
        sudo rm -f "${BIN_DIR}/${bin}"
    else
        echo "  - ${bin} no existe en /opt/bin (OK)"
    fi
done

# Intentar eliminar /opt/bin si está vacío
sudo rmdir "$BIN_DIR" 2>/dev/null || true


# -----------------------------------------------------
# 2) Eliminar symlinks en /usr/local/bin
# -----------------------------------------------------
echo "[2/6] Eliminando symlinks en /usr/local/bin..."

for bin in oc kubectl openshift-install; do
    if [[ -L "${USR_BIN_DIR}/${bin}" ]]; then
        echo "  - Eliminando symlink ${USR_BIN_DIR}/${bin}"
        sudo rm -f "${USR_BIN_DIR}/${bin}"
    fi
done


# -----------------------------------------------------
# 3) Eliminar el archivo de perfil que añadía /opt/bin
# -----------------------------------------------------
echo "[3/6] Eliminando /etc/profile.d/okd-path.sh..."

if [[ -f "$PROFILE_D" ]]; then
    sudo rm -f "$PROFILE_D"
    echo "  ✔ Archivo eliminado"
else
    echo "  - No existe, OK"
fi


# -----------------------------------------------------
# 4) Limpiar PATH del ~/.bashrc del usuario
# -----------------------------------------------------
echo "[4/6] Limpiando PATH en ~/.bashrc..."

if grep -q "/opt/bin" "$BASHRC"; then
    sed -i '/\/opt\/bin/d' "$BASHRC"
    echo "  ✔ Entrada /opt/bin eliminada"
else
    echo "  - No había entrada (OK)"
fi


# -----------------------------------------------------
# 5) Eliminar logs, estados y cache de openshift-install
# -----------------------------------------------------
echo "[5/6] Eliminando estado interno de openshift-install..."

rm -f .openshift_install*.log            2>/dev/null || true
rm -f .openshift_install_state.json*     2>/dev/null || true
rm -f .openshift_install.lock*           2>/dev/null || true
rm -rf ~/.cache/openshift-install        2>/dev/null || true

echo "  ✔ Estado limpiado"


# -----------------------------------------------------
# 6) Limpiar carpetas temporales de instalación
# -----------------------------------------------------
echo "[6/6] Eliminando carpeta temporal ${TMP_DIR}..."

sudo rm -rf "$TMP_DIR" 2>/dev/null || true
echo "  ✔ Carpeta temporal eliminada"


echo "=============================================="
echo "    OKD DESINSTALADO COMPLETAMENTE 🎉"
echo "=============================================="