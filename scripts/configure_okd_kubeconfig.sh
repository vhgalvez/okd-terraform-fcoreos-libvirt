#!/usr/bin/env bash
set -euo pipefail

echo "==============================================="
echo "  Configurando kubeconfig para OKD"
echo "==============================================="

KCFG="$HOME/.kube/config"
OKD_SOURCE="install-config/auth/kubeconfig"

# --------------------------------------------------------------------
# 1) Configurar PATH de root para incluir /opt/bin
# --------------------------------------------------------------------
echo "[+] Asegurando que /opt/bin está en el PATH de root..."

if ! sudo grep -q "/opt/bin" /root/.bashrc; then
    sudo bash -c 'echo "export PATH=/opt/bin:\$PATH" >> /root/.bashrc'
    echo "[+] /opt/bin añadido al PATH de root"
else
    echo "[+] /opt/bin ya estaba configurado en el PATH de root"
fi

# Recargar PATH solo para esta ejecución
export PATH="/opt/bin:$PATH"

# --------------------------------------------------------------------
# 2) Configurar kubeconfig
# --------------------------------------------------------------------
echo
echo "[+] Configurando kubeconfig..."

# Eliminar kubeconfig previo
if [ -f "$KCFG" ]; then
    echo "[+] Eliminando kubeconfig previo: $KCFG"
    rm -f "$KCFG"
fi

mkdir -p "$HOME/.kube"

if [ -f "$OKD_SOURCE" ]; then
    echo "[+] Copiando kubeconfig desde $OKD_SOURCE → ~/.kube/config"
    cp "$OKD_SOURCE" "$KCFG"
    chmod 600 "$KCFG"
else
    echo "❌ ERROR: No se encontró kubeconfig en: $OKD_SOURCE"
    exit 1
fi

echo "[✔] kubeconfig configurado correctamente."

# --------------------------------------------------------------------
# 3) Verificación de oc y conexión al cluster
# --------------------------------------------------------------------
echo
echo "==============================================="
echo "  Verificando herramientas de OKD"
echo "==============================================="

echo -n "[*] Verificando oc en el PATH... "
if command -v oc >/dev/null 2>&1; then
    echo "✔ encontrado: $(command -v oc)"
else
    echo "❌ NO encontrado"
fi

echo "[*] Versión de oc:"
oc version --client || echo "⚠ oc instalado pero sin conexión al cluster"

echo
echo "[*] Probar conexión (oc whoami):"
oc whoami || echo "⚠ Aún no hay conexión al cluster (bootstrap/másters no listos)"

echo
echo "==============================================="
echo "  kubeconfig de OKD instalado y entorno listo."
echo "==============================================="