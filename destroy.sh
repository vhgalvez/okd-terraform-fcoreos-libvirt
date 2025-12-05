#!/bin/bash
# destroy.sh — Limpieza total del cluster OKD + Terraform
set -euo pipefail

echo "=============================================="
echo "      ELIMINANDO CLUSTER OKD COMPLETAMENTE"
echo "=============================================="

# -----------------------------------------------
# 1. Destruir infraestructura Terraform
# -----------------------------------------------
if [[ -d "terraform" ]]; then
    echo "[1/5] Ejecutando terraform destroy..."
    terraform -chdir=terraform destroy -auto-approve || true
else
    echo "⚠ Carpeta terraform/ no encontrada, saltando destroy."
fi

# -----------------------------------------------
# 2. Eliminar Ignition generada por el installer
# -----------------------------------------------
echo "[2/5] Eliminando Ignition vieja..."
rm -f ignition/bootstrap.ign 2>/dev/null || true
rm -f ignition/master.ign    2>/dev/null || true
rm -f ignition/worker.ign    2>/dev/null || true

# -----------------------------------------------
# 3. Eliminar archivos generados por openshift-install
# -----------------------------------------------
echo "[3/5] Limpiando install-config/..."

rm -f  install-config/bootstrap.ign 2>/dev/null || true
rm -f  install-config/master.ign    2>/dev/null || true
rm -f  install-config/worker.ign    2>/dev/null || true
rm -f  install-config/metadata.json 2>/dev/null || true

rm -rf install-config/manifests     2>/dev/null || true
rm -rf install-config/openshift     2>/dev/null || true

# ⚠️ Eliminar credenciales generadas
rm -rf install-config/auth          2>/dev/null || true

# ⚠️ NO ELIMINAR: install-config.yaml
# (debe permanecer para regenerar ignitions nuevas)

# -----------------------------------------------
# 4. ELIMINAR ARCHIVOS OCULTOS DEL INSTALLER
# -----------------------------------------------
echo "[4/5] Eliminando estado oculto de openshift-install..."

rm -f .openshift_install.log                2>/dev/null || true
rm -f .openshift_install_state.json         2>/dev/null || true
rm -f .openshift_install_state.json.backup  2>/dev/null || true

# Algunas versiones generan un lock
rm -f .openshift_install.lock*              2>/dev/null || true

# -----------------------------------------------
# 5. LIMPIEZA PROFUNDA DEL CACHE
# -----------------------------------------------
echo "[5/5] Eliminando cache antigua de openshift-install..."

rm -rf ~/.cache/openshift-install           2>/dev/null || true


echo "=============================================="
echo "   CLEAN STATE COMPLETO — TODO ELIMINADO"
echo "   Listo para regenerar Ignition SIN errores"
echo "=============================================="