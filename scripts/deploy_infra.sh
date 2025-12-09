#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

TERRAFORM_DIR="${PROJECT_ROOT}/terraform"

echo "=============================================="
echo "  STEP 2: DEPLOY INFRA (TERRAFORM)"
echo "=============================================="

if [[ ! -f "generated/ignition/bootstrap.ign" ]]; then
    echo "❌ ERROR: No existen Ignitions. Ejecuta primero:"
    echo "   scripts/01_generate_ignition.sh"
    exit 1
fi

echo "[1/3] terraform init"
terraform -chdir="$TERRAFORM_DIR" init -input=false

TFVARS=()
[[ -f "${TERRAFORM_DIR}/terraform.tfvars" ]] && TFVARS+=( -var-file="terraform.tfvars" )

echo "[2/3] terraform apply (parallelism=1 para evitar saturación)"
terraform -chdir="$TERRAFORM_DIR" apply -auto-approve -parallelism=1 "${TFVARS[@]}"

echo "[3/3] Mostrando outputs:"
terraform -chdir="$TERRAFORM_DIR" output || true

echo "=============================================="
echo "  ✔ INFRA CREADA EXITOSAMENTE"
echo "=============================================="
