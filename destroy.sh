#!/bin/bash
set -euo pipefail

echo "=============================================="
echo "     ELIMINANDO CLUSTER OKD + TERRAFORM"
echo "=============================================="


# -----------------------------------------------
# 1. Destruir infraestructura Terraform
# -----------------------------------------------
if [[ -d "terraform" ]]; then
    echo "[1/3] Ejecutando terraform destroy..."
    terraform -chdir=terraform destroy -auto-approve
else
    echo "⚠ Carpeta terraform/ no encontrada, saltando destroy."
fi


# -----------------------------------------------
# 2. Eliminar archivos Ignition generados en /ignition
# -----------------------------------------------
echo "[2/3] Eliminando archivos Ignition..."
rm -f ignition/bootstrap.ign     2>/dev/null || true
rm -f ignition/master.ign        2>/dev/null || true
rm -f ignition/worker.ign        2>/dev/null || true


# -----------------------------------------------
# 3. Eliminar archivos generados en install-config (NO destruir install-config.yaml)
# -----------------------------------------------
echo "[3/3] Limpiando directorios generados por openshift-install..."

rm -rf install-config/manifests      2>/dev/null || true
rm -rf install-config/openshift      2>/dev/null || true
rm -f  install-config/bootstrap.ign  2>/dev/null || true
rm -f  install-config/master.ign     2>/dev/null || true
rm -f  install-config/worker.ign     2>/dev/null || true
rm -f  install-config/metadata.json  2>/dev/null || true

# ⚠️ MUY IMPORTANTE:
# NO se elimina install-config/install-config.yaml
# porque es tu archivo de configuración original.


echo "=============================================="
echo "     CLUSTER OKD ELIMINADO EXITOSAMENTE"
echo "=============================================="
