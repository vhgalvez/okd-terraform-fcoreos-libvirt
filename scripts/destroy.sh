#!/usr/bin/env bash
# scripts/destroy.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

GENERATED_DIR="${PROJECT_ROOT}/generated"
TERRAFORM_DIR="${PROJECT_ROOT}/terraform"

echo "=============================================="
echo "      ELIMINANDO CLUSTER OKD COMPLETAMENTE"
echo "=============================================="

# ---------------------------------------------------------
# 1. Terraform destroy
# ---------------------------------------------------------
if [[ -d "$TERRAFORM_DIR" ]]; then
    echo "[1/6] Ejecutando terraform destroy..."
    terraform -chdir="$TERRAFORM_DIR" destroy -auto-approve || true
else
    echo "⚠ terraform/ no encontrado, saltando destroy."
fi

# ---------------------------------------------------------
# 2. Eliminar carpeta generated/ SIEMPRE, COMPLETA
# ---------------------------------------------------------
echo "[2/6] Eliminando carpeta generated/ COMPLETA..."

rm -rf "${GENERATED_DIR}"

echo "✔ generated/ eliminada por completo."

# ---------------------------------------------------------
# 3. Archivos openshift-install
# ---------------------------------------------------------
echo "[3/6] Eliminando archivos openshift-install..."

rm -f "${PROJECT_ROOT}/.openshift_install.log"*        2>/dev/null || true
rm -f "${PROJECT_ROOT}/.openshift_install_state.json"* 2>/dev/null || true
rm -f "${PROJECT_ROOT}/.openshift_install.lock"*       2>/dev/null || true

echo "✔ Archivos openshift-install eliminados."

# ---------------------------------------------------------
# 4. Eliminar ignitions .ign en todo el proyecto
# ---------------------------------------------------------
echo "[4/6] Eliminando ignitions viejos (.ign)..."

find "$PROJECT_ROOT" -type f -name "*.ign" -exec rm -f {} \; 2>/dev/null || true

echo "✔ Ignitions eliminados."

# ---------------------------------------------------------
# 5. Eliminar auth (symlink o carpeta)
# ---------------------------------------------------------
echo "[5/6] Eliminando auth..."

if [[ -L "${PROJECT_ROOT}/auth" ]]; then
    rm -f "${PROJECT_ROOT}/auth"
    echo "✔ symlink auth eliminado."
    
    elif [[ -d "${PROJECT_ROOT}/auth" ]]; then
    rm -rf "${PROJECT_ROOT}/auth"
    echo "✔ directorio auth eliminado."
    
else
    echo "✔ auth no existe (correcto)."
fi

# ---------------------------------------------------------
# 6. Cache openshift-install
# ---------------------------------------------------------
echo "[6/6] Eliminando cache ~/.cache/openshift-install..."

rm -rf ~/.cache/openshift-install 2>/dev/null || true

echo "✔ Cache eliminada."

echo "=============================================="
echo "   CLEAN STATE COMPLETO — TODO ELIMINADO"
echo "=============================================="