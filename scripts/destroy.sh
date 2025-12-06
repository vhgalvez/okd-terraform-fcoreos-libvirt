#!/bin/bash

# destroy.sh — Limpieza total del cluster OKD + Terraform
set -euo pipefail

GENERATED_DIR="generated"

echo "=============================================="
echo "      ELIMINANDO CLUSTER OKD COMPLETAMENTE"
echo "=============================================="

# -----------------------------------------------
# 1. Destruir infraestructura Terraform
# -----------------------------------------------
if [[ -d "terraform" ]]; then
    echo "[1/3] Ejecutando terraform destroy..."
    terraform -chdir=terraform destroy -auto-approve || true
else
    echo "⚠ Carpeta terraform/ no encontrada, saltando destroy."
fi

# -----------------------------------------------
# 2. Eliminar directorio generated completo
# -----------------------------------------------
echo "[2/3] Eliminando archivos generados..."
rm -rf "${GENERATED_DIR:?}/"* 2>/dev/null || true
echo "✔ Carpeta generated/ limpiada."

# -----------------------------------------------
# 3. Eliminar archivos ocultos del installer
# -----------------------------------------------
echo "[3/3] Eliminando estado interno de openshift-install..."

rm -f .openshift_install.log                2>/dev/null || true
rm -f .openshift_install_state.json         2>/dev/null || true
rm -f .openshift_install_state.json.backup  2>/dev/null || true
rm -f .openshift_install.lock*              2>/dev/null || true
rm -rf ~/.cache/openshift-install           2>/dev/null || true

echo "=============================================="
echo "   CLEAN STATE COMPLETO — TODO ELIMINADO"
echo "   install-config.yaml preservado SIEMPRE"
echo "=============================================="
