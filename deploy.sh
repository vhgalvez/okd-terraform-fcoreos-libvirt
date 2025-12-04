#!/usr/bin/env bash
set -euo pipefail

# ----------------------------------------
#  Deploy de OKD usando Terraform + Ignition
# ----------------------------------------

INSTALL_DIR="install-config"
IGNITION_DIR="ignition"
TERRAFORM_DIR="terraform"
OPENSHIFT_INSTALL_BIN="/opt/bin/openshift-install"

echo "=============================================="
echo "  DEPLOY AUTOMÁTICO DE OKD 4.x"
echo "=============================================="

# --- Validaciones previas ---

if [[ ! -x "$OPENSHIFT_INSTALL_BIN" ]]; then
    echo "❌ ERROR: openshift-install no está en /opt/bin o no es ejecutable."
    echo "   Ejecuta antes: ./install_okd_tools.sh"
    exit 1
fi

if [[ ! -d "$INSTALL_DIR" ]]; then
    echo "❌ ERROR: No existe la carpeta $INSTALL_DIR/ con install-config.yaml"
    echo "   Debes ejecutar: openshift-install create install-config --dir=$INSTALL_DIR"
    exit 1
fi


# ----------------------------------------
# 1. Generar Ignition
# ----------------------------------------
echo "[1/5] Generando Ignition..."

$OPENSHIFT_INSTALL_BIN create ignition-configs --dir="$INSTALL_DIR"

echo "✔ Ignition generado correctamente."


# ----------------------------------------
# 2. Copiar Ignition a carpeta /ignition
# ----------------------------------------
echo "[2/5] Copiando archivos .ign a $IGNITION_DIR/"

mkdir -p "$IGNITION_DIR"

shopt -s nullglob
IGN_FILES=("$INSTALL_DIR"/*.ign)

if (( ${#IGN_FILES[@]} == 0 )); then
    echo "❌ ERROR: No se generaron archivos .ign"
    exit 1
fi

cp "$INSTALL_DIR"/*.ign "$IGNITION_DIR"/
echo "✔ Archivos copiados a $IGNITION_DIR/"


# ----------------------------------------
# 3. Terraform apply
# ----------------------------------------
echo "[3/5] Ejecutando Terraform..."

if [[ ! -d "$TERRAFORM_DIR" ]]; then
    echo "❌ ERROR: La carpeta terraform/ no existe."
    exit 1
fi

cd "$TERRAFORM_DIR"

terraform init -input=false
terraform apply -auto-approve -input=false

cd ..

echo "✔ Terraform aplicado correctamente."


# ----------------------------------------
# 4. Mostrar IPs del cluster
# ----------------------------------------
echo "[4/5] Mostrando outputs de Terraform:"

terraform -chdir="$TERRAFORM_DIR" output || echo "⚠ No hay outputs disponibles."


# ----------------------------------------
# 5. Deploy finalizado
# ----------------------------------------
echo "[5/5] Instalación completada exitosamente."
echo "=============================================="
echo "Cluster desplegado. Ejecuta:"
echo "   terraform -chdir=terraform output"
echo "para ver las IPs nuevamente."
echo "=============================================="
