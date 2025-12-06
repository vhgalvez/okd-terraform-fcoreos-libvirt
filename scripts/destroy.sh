#!/usr/bin/env bash

# scripts/destroy.sh
set -euo pipefail

# Obtener la ruta absoluta del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ir al directorio raíz del proyecto
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

GENERATED_DIR="${PROJECT_ROOT}/generated"
TERRAFORM_DIR="${PROJECT_ROOT}/terraform"

echo "=============================================="
echo "      ELIMINANDO CLUSTER OKD COMPLETAMENTE"
echo "=============================================="

# -----------------------------------------------
# 1. Destruir infraestructura Terraform
# -----------------------------------------------
if [[ -d "$TERRAFORM_DIR" ]]; then
    echo "[1/3] Ejecutando terraform destroy..."
    terraform -chdir="$TERRAFORM_DIR" destroy -auto-approve || true
else
    echo "⚠ Carpeta terraform/ no encontrada, saltando destroy."
fi

# -----------------------------------------------
# 2. Limpiar carpeta generated/
# -----------------------------------------------
echo "[2/3] Eliminando archivos generados..."

if [[ -d "$GENERATED_DIR" ]]; then
    rm -rf "${GENERATED_DIR:?}/"* 2>/dev/null || true
    echo "✔ Carpeta generated/ limpiada."
else
    echo "⚠ Carpeta generated/ no existe, nada que limpiar."
fi

# -----------------------------------------------
# 3. Eliminar archivos ocultos del installer
# -----------------------------------------------
echo "[3/3] Eliminando estado interno de openshift-install..."

rm -f "${PROJECT_ROOT}"/.openshift_install.log*      2>/dev/null || true
rm -f "${PROJECT_ROOT}"/.openshift_install_state.json* 2>/dev/null || true
rm -f "${PROJECT_ROOT}"/.openshift_install.lock*     2>/dev/null || true
rm -rf ~/.cache/openshift-install                    2>/dev/null || true

echo "=============================================="
echo "   CLEAN STATE COMPLETO — TODO ELIMINADO"
echo "   cluster OKD destruido exitosamente."
echo "=============================================="
