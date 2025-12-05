#!/usr/bin/env bash
set -euo pipefail

echo "==============================================="
echo "  Configurando kubeconfig para OKD"
echo "==============================================="

KCFG="$HOME/.kube/config"
OKD_SOURCE="auth/kubeconfig"

# Borrar kubeconfig previo
if [ -f "$KCFG" ]; then
    echo "[+] Eliminando kubeconfig previo"
    rm -f "$KCFG"
fi

# Crear carpeta ~/.kube
mkdir -p "$HOME/.kube"

# Copiar kubeconfig
if [ -f "$OKD_SOURCE" ]; then
    echo "[+] Copiando kubeconfig → ~/.kube/config"
    cp "$OKD_SOURCE" "$KCFG"
    chmod 600 "$KCFG"
else
    echo "❌ ERROR: No se encontró auth/kubeconfig"
    exit 1
fi

echo
echo "[✔] kubeconfig configurado"
echo "[→] Prueba: oc whoami"
oc whoami || echo "⚠ Aún no hay conexión al cluster (bootstrap/másters no listos)"

echo "==============================================="
echo "  kubeconfig de OKD instalado correctamente."
echo "==============================================="
