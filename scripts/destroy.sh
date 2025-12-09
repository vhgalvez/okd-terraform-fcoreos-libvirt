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
# 1. Destruir infraestructura Terraform
# ---------------------------------------------------------
if [[ -d "$TERRAFORM_DIR" ]]; then
    echo "[1/5] Ejecutando terraform destroy..."
    terraform -chdir="$TERRAFORM_DIR" destroy -auto-approve || true
else
    echo "⚠ Carpeta terraform/ no encontrada, saltando destroy."
fi

# ---------------------------------------------------------
# 2. Limpiar carpeta generated/
# ---------------------------------------------------------
echo "[2/5] Eliminando carpeta generated/ completa..."

if [[ -d "$GENERATED_DIR" ]]; then
    rm -rf "${GENERATED_DIR:?}/"*
    echo "✔ generated/ limpiada."
else
    echo "⚠ generated/ no existe, nada que limpiar."
fi

# ---------------------------------------------------------
# 3. Eliminar COPIAS obsoletas de install-config
# ---------------------------------------------------------
echo "[3/5] Eliminando copia temporal install-config.yaml dentro de generated/..."

if [[ -f "${GENERATED_DIR}/install-config.yaml" ]]; then
    rm -f "${GENERATED_DIR}/install-config.yaml"
    echo "✔ Copia eliminada: generated/install-config.yaml"
else
    echo "✔ No había copia temporal de install-config.yaml (correcto)."
fi

# Además: borrar cualquier .ign viejo que quede por el proyecto
echo "[3b/5] Eliminando archivos .ign obsoletos..."
find "$PROJECT_ROOT" -type f -name "*.ign" -exec rm -f {} \; 2>/dev/null || true
echo "✔ Ignitions viejas eliminadas."

# ---------------------------------------------------------
# 4. Eliminar symlink 'auth' si existe
# ---------------------------------------------------------
echo "[4/5] Eliminando symlink auth si existe..."

if [[ -L "${PROJECT_ROOT}/auth" ]]; then
    rm -f "${PROJECT_ROOT}/auth"
    echo "✔ Symlink auth eliminado."
    elif [[ -d "${PROJECT_ROOT}/auth" ]]; then
    echo "⚠ 'auth' existe como directorio normal. No se elimina (por seguridad)."
else
    echo "✔ No existe 'auth' en el root del proyecto (correcto)."
fi

# ---------------------------------------------------------
# 5. Limpiar archivos internos de openshift-install
# ---------------------------------------------------------
echo "[5/5] Eliminando estado interno de openshift-install..."

rm -f "${PROJECT_ROOT}"/.openshift_install.log*         2>/dev/null || true
rm -f "${PROJECT_ROOT}"/.openshift_install_state.json*  2>/dev/null || true
rm -f "${PROJECT_ROOT}"/.openshift_install.lock*        2>/dev/null || true
rm -rf ~/.cache/openshift-install                      2>/dev/null || true

echo "=============================================="
echo "   CLEAN STATE COMPLETO — TODO ELIMINADO"
echo "   OKD completamente destruido y reseteado."
echo "=============================================="
