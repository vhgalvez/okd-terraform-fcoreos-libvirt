#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

INSTALL_DIR="${PROJECT_ROOT}/install-config"
GENERATED_DIR="${PROJECT_ROOT}/generated"
IGNITION_DIR="${GENERATED_DIR}/ignition"
OPENSHIFT_INSTALL_BIN="/opt/bin/openshift-install"

echo "=============================================="
echo "  STEP 1: GENERAR IGNITIONS + CERTIFICADOS"
echo "=============================================="

# Validaciones
if [[ ! -x "$OPENSHIFT_INSTALL_BIN" ]]; then
    echo "❌ ERROR: openshift-install no está en: $OPENSHIFT_INSTALL_BIN"
    exit 1
fi

if [[ ! -f "${INSTALL_DIR}/install-config.yaml" ]]; then
    echo "❌ ERROR: No existe ${INSTALL_DIR}/install-config.yaml"
    exit 1
fi

mkdir -p "${IGNITION_DIR}"

echo "[0/3] Limpiando registros previos…"
rm -f "${GENERATED_DIR}"/*.ign 2>/dev/null || true
rm -f "${IGNITION_DIR}"/*.ign 2>/dev/null || true
rm -f "${PROJECT_ROOT}"/.openshift_install* 2>/dev/null || true

echo "[1/3] Copiando install-config.yaml…"
cp -f "${INSTALL_DIR}/install-config.yaml" "${GENERATED_DIR}/install-config.yaml"

# -------------------------------
# NTP SYNC (control crítico)
# -------------------------------
echo "[CHECK] Verificando sincronización del reloj…"
if ! chronyc tracking | grep -q "Leap status.*Normal"; then
    echo "⚠ Reloj no sincronizado. Esperando NTP…"
    chronyc waitsync
fi

echo "✔ NTP sincronizado correctamente:"
chronyc tracking | sed 's/^/   /'

# -------------------------------
# Generación de Ignitions
# -------------------------------
echo "[2/3] Generando Ignition + Certificados…"
"$OPENSHIFT_INSTALL_BIN" create ignition-configs --dir="$GENERATED_DIR"

mv -f "${GENERATED_DIR}"/*.ign "${IGNITION_DIR}/" 2>/dev/null || true

echo "[3/3] Mostrando fechas de certificados…"
grep -R "Not Before" -n generated/auth 2>/dev/null || true
grep -R "Not After" -n generated/auth 2>/dev/null || true

echo "=============================================="
echo "  ✔ IGNITIONS GENERADAS EXITOSAMENTE"
echo "  Ahora ejecuta: scripts/02_deploy_infra.sh"
echo "=============================================="
