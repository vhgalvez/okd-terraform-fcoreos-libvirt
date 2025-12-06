#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="install-config"
IGNITION_DIR="ignition"
TERRAFORM_DIR="terraform"
OPENSHIFT_INSTALL_BIN="/opt/bin/openshift-install"

echo "=============================================="
echo "  DEPLOY AUTOMÁTICO DE OKD 4.x"
echo "=============================================="

# ----------------------------------------
# Validaciones previas
# ----------------------------------------

if [[ ! -x "$OPENSHIFT_INSTALL_BIN" ]]; then
    echo "❌ ERROR: openshift-install no está en /opt/bin"
    exit 1
fi

if [[ ! -f "${INSTALL_DIR}/install-config.yaml" ]]; then
    echo "❌ ERROR: Falta ${INSTALL_DIR}/install-config.yaml"
    exit 1
fi

mkdir -p "$IGNITION_DIR"

# ----------------------------------------
# 1. Generar Ignition
# ----------------------------------------

echo "[1/5] Generando Ignition..."
"$OPENSHIFT_INSTALL_BIN" create ignition-configs --dir="$INSTALL_DIR"
echo "✔ Ignition generado."

# ----------------------------------------
# 2. Copiar Ignition
# ----------------------------------------

echo "[2/5] Copiando ignitions a ${IGNITION_DIR}/..."
cp "$INSTALL_DIR"/*.ign "$IGNITION_DIR"/
echo "✔ Ignitions copiadas."

# ----------------------------------------
# 3. Terraform apply
# ----------------------------------------

echo "[3/5] Ejecutando Terraform..."

terraform -chdir="$TERRAFORM_DIR" init -input=false

TFVARS=()
if [[ -f "${TERRAFORM_DIR}/terraform.tfvars" ]]; then
    TFVARS+=( -var-file="terraform.tfvars" )
fi

terraform -chdir="$TERRAFORM_DIR" apply -auto-approve -input=false "${TFVARS[@]}"

echo "✔ Terraform completado."

# ----------------------------------------
# 4. Outputs
# ----------------------------------------

echo "[4/5] Outputs del cluster:"
terraform -chdir="$TERRAFORM_DIR" output || true

# ----------------------------------------
# 5. Final
# ----------------------------------------

echo "=============================================="
echo "  Deploy completado con éxito"
echo "  Usa: terraform -chdir=terraform output"
echo "=============================================="
