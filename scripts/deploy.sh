#!/usr/bin/env bash
# scripts/deploy.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# =====================================================
# Crear carpetas necesarias desde el inicio
# =====================================================
mkdir -p "${PROJECT_ROOT}/generated"
mkdir -p "${PROJECT_ROOT}/generated/ignition"

INSTALL_DIR="${PROJECT_ROOT}/install-config"
GENERATED_DIR="${PROJECT_ROOT}/generated"
IGNITION_DIR="${GENERATED_DIR}/ignition"
TERRAFORM_DIR="${PROJECT_ROOT}/terraform"
OPENSHIFT_INSTALL_BIN="/opt/bin/openshift-install"

echo "=============================================="
echo "    DEPLOY AUTOMÁTICO DE OKD 4.x"
echo "=============================================="

# ----------------------------------------------------
# 0. Validaciones previas
# ----------------------------------------------------

if [[ ! -x "$OPENSHIFT_INSTALL_BIN" ]]; then
    echo "❌ ERROR: openshift-install no está en: $OPENSHIFT_INSTALL_BIN"
    exit 1
fi

if [[ ! -f "${INSTALL_DIR}/install-config.yaml" ]]; then
    echo "❌ ERROR: No existe ${INSTALL_DIR}/install-config.yaml"
    exit 1
fi

# ----------------------------------------------------
# 1. Limpieza ligera
# ----------------------------------------------------
echo "[0/5] Preparando entorno (limpieza ligera)..."

rm -f "${GENERATED_DIR}"/*.ign 2>/dev/null || true
rm -f "${IGNITION_DIR}"/*.ign 2>/dev/null || true

rm -f "${PROJECT_ROOT}"/.openshift_install.log*        2>/dev/null || true
rm -f "${PROJECT_ROOT}"/.openshift_install_state.json* 2>/dev/null || true
rm -f "${PROJECT_ROOT}"/.openshift_install.lock*       2>/dev/null || true

# ----------------------------------------------------
# 2. Copiar install-config.yaml
# ----------------------------------------------------
cp -f "${INSTALL_DIR}/install-config.yaml" "${GENERATED_DIR}/install-config.yaml"
echo "✔ install-config.yaml copiado a generated/"

# ----------------------------------------------------
# 3. Generar Ignition
# ----------------------------------------------------
echo "[1/5] Generando Ignition en ${GENERATED_DIR}/..."
"$OPENSHIFT_INSTALL_BIN" create ignition-configs --dir="$GENERATED_DIR"
echo "✔ Ignition generado correctamente."

echo "[+] Moviendo Ignition a ${IGNITION_DIR}/..."
mv -f "${GENERATED_DIR}"/*.ign "${IGNITION_DIR}/" 2>/dev/null || true
echo "✔ Ignitions organizadas."

# ----------------------------------------------------
# 4. Crear symlink auth → generated/auth
# ----------------------------------------------------
echo "[2/5] Verificando symlink 'auth'..."

if [[ -L "${PROJECT_ROOT}/auth" ]]; then
    echo "✔ Symlink existente: auth → generated/auth"
    
    elif [[ -d "${PROJECT_ROOT}/auth" ]]; then
    echo "⚠ Directorio 'auth' existe y NO es symlink. Eliminando..."
    rm -rf "${PROJECT_ROOT}/auth"
    ln -s generated/auth auth
    echo "✔ Symlink creado: auth → generated/auth"
    
else
    ln -s generated/auth auth
    echo "✔ Symlink creado: auth → generated/auth"
fi

echo "[+] Contenido de generated/auth:"
ls -l "${PROJECT_ROOT}/generated/auth" || echo "⚠ WARNING: auth vacío (Terraform aún no creó VMs)"

# ----------------------------------------------------
# 5. Terraform init & apply
# ----------------------------------------------------
echo "[3/5] Ejecutando terraform init..."
terraform -chdir="$TERRAFORM_DIR" init -input=false

TFVARS=()
if [[ -f "${TERRAFORM_DIR}/terraform.tfvars" ]]; then
    TFVARS+=( -var-file="terraform.tfvars" )
fi

echo "[4/5] Ejecutando terraform apply..."
terraform -chdir="$TERRAFORM_DIR" apply -auto-approve "${TFVARS[@]}"
echo "✔ Terraform aplicó la infraestructura correctamente."

# ----------------------------------------------------
# 6. Outputs
# ----------------------------------------------------
echo "[5/5] Outputs del cluster:"
terraform -chdir="$TERRAFORM_DIR" output || true

echo "=============================================="
echo "    Deploy completado con éxito"
echo "=============================================="