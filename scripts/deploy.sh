#!/usr/bin/env bash

# scripts/deploy.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

INSTALL_DIR="${PROJECT_ROOT}/install-config"
GENERATED_DIR="${PROJECT_ROOT}/generated"
IGNITION_DIR="${GENERATED_DIR}/ignition"
TERRAFORM_DIR="${PROJECT_ROOT}/terraform"
OPENSHIFT_INSTALL_BIN="/opt/bin/openshift-install"

echo "=============================================="
echo "  DEPLOY AUTOMÁTICO DE OKD 4.x"
echo "=============================================="

# ----------------------------------------------------
# Validaciones previas
# ----------------------------------------------------

if [[ ! -x "$OPENSHIFT_INSTALL_BIN" ]]; then
    echo "❌ ERROR: openshift-install no está en: $OPENSHIFT_INSTALL_BIN"
    exit 1
fi

if [[ ! -f "${INSTALL_DIR}/install-config.yaml" ]]; then
    echo "❌ ERROR: No existe ${INSTALL_DIR}/install-config.yaml"
    exit 1
fi

mkdir -p "${IGNITION_DIR}"

# ----------------------------------------------------
# 1. Copiar install-config.yaml a generated/
# ----------------------------------------------------
echo "[0/4] Preparando entorno..."

cp -f "${INSTALL_DIR}/install-config.yaml" "${GENERATED_DIR}/install-config.yaml"

echo "✔ install-config.yaml copiado a generated/"

# ----------------------------------------------------
# 2. Generar Ignition
# ----------------------------------------------------
echo "[1/4] Generando Ignition en ${GENERATED_DIR}/..."
"$OPENSHIFT_INSTALL_BIN" create ignition-configs --dir="$GENERATED_DIR"
echo "✔ Ignition generado correctamente."

# Mover ignitions a generated/ignition/
echo "[+] Moviendo Ignition a ${IGNITION_DIR}/..."
mkdir -p "${IGNITION_DIR}"
mv -f "${GENERATED_DIR}"/*.ign "${IGNITION_DIR}/" 2>/dev/null || true

echo "✔ Ignitions organizadas."

# ----------------------------------------------------
# 3. Terraform init y apply
# ----------------------------------------------------
echo "[2/4] Ejecutando terraform init..."
terraform -chdir="$TERRAFORM_DIR" init -input=false

TFVARS=()
if [[ -f "${TERRAFORM_DIR}/terraform.tfvars" ]]; then
    TFVARS+=( -var-file="terraform.tfvars" )
fi

echo "[3/4] Ejecutando terraform apply..."
terraform -chdir="$TERRAFORM_DIR" apply -auto-approve "${TFVARS[@]}"

echo "✔ Terraform aplicó la infraestructura correctamente."

# ----------------------------------------------------
# 4. Outputs finales
# ----------------------------------------------------
echo "[4/4] Outputs del cluster:"
terraform -chdir="$TERRAFORM_DIR" output || true

echo "=============================================="
echo "  Deploy completado con éxito"
echo "=============================================="
