#!/usr/bin/env bash

# scripts/configure_okd_kubeconfig.sh
set -euo pipefail

echo "==============================================="
echo "  Configurando kubeconfig para OKD"
echo "===============================================""

KCFG="$HOME/.kube/config"
OKD_SOURCE="generated/auth/kubeconfig"

# --------------------------------------------------------------------
# 1) Asegurar que root tiene /opt/bin en el PATH
# --------------------------------------------------------------------
echo "[+] Asegurando que /opt/bin está en el PATH de root..."

if ! sudo grep -q "/opt/bin" /root/.bashrc 2>/dev/null; then
    sudo bash -c 'echo "export PATH=/opt/bin:\$PATH" >> /root/.bashrc'
    echo "[+] /opt/bin añadido al PATH de root"
else
    echo "[+] /opt/bin ya estaba configurado en el PATH de root"
fi

export PATH="/opt/bin:$PATH"  # Cargar PATH actualizado para esta sesión

# --------------------------------------------------------------------
# 2) Configurar kubeconfig
# --------------------------------------------------------------------
echo
echo "[+] Configurando kubeconfig..."

# Eliminar kubeconfig previo
if [ -f "$KCFG" ]; then
    echo "[+] Eliminando kubeconfig previo en: $KCFG"
    rm -f "$KCFG"
fi

mkdir -p "$HOME/.kube"

if [ -f "$OKD_SOURCE" ]; then
    echo "[+] Copiando kubeconfig desde $OKD_SOURCE → ~/.kube/config"
    cp "$OKD_SOURCE" "$KCFG"
    chmod 600 "$KCFG"
else
    echo "❌ ERROR: No se encontró kubeconfig en: $OKD_SOURCE"
    echo "    Asegúrate de haber ejecutado deploy.sh y que OKD generó auth/kubeconfig"
    exit 1
fi

echo "✔ kubeconfig configurado correctamente."

# --------------------------------------------------------------------
# 3) Verificación de oc y conexión al cluster
# --------------------------------------------------------------------
echo
echo "==============================================="
echo "  Verificando herramientas de OKD"
echo "===============================================""

echo -n "[*] Verificando oc en el PATH... "
if command -v oc >/dev/null 2>&1; then
    echo "✔ encontrado: $(command -v oc)"
else
    echo "❌ NO encontrado"
fi

echo "[*] Versión de oc:"
oc version --client || echo "⚠ oc instalado pero sin conexión al cluster"

echo
echo "[*] Probando conexión al cluster (oc whoami):"
oc whoami || echo "⚠ Aún no hay conexión al cluster (bootstrap/master no listos)"

echo
echo "==============================================="
echo "  kubeconfig de OKD configurado. Entorno listo."
echo "==============================================="
