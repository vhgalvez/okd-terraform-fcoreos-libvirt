#!/usr/bin/env bash

#scripts\configure_okd_kubeconfig.sh 

set -euo pipefail

echo "==============================================="
echo "  Configurando kubeconfig para OKD"
echo "==============================================="

KCFG="$HOME/.kube/config"
OKD_SOURCE="generated/auth/kubeconfig"

# --------------------------------------------------------------------
# 1) Asegurar PATH global para OKD (/opt/bin)
# --------------------------------------------------------------------
echo "[+] Asegurando que /opt/bin está en el PATH del sistema..."

if [ ! -f /etc/profile.d/okd-path.sh ]; then
    sudo bash -c 'echo "export PATH=/opt/bin:\$PATH" > /etc/profile.d/okd-path.sh'
    sudo chmod +x /etc/profile.d/okd-path.sh
    echo "[+] Creado /etc/profile.d/okd-path.sh"
else
    echo "[+] /etc/profile.d/okd-path.sh ya existe"
fi

# Usar PATH actualizado ya en este script
export PATH="/opt/bin:$PATH"

# --------------------------------------------------------------------
# 2) Crear enlaces simbólicos en /usr/local/bin
# --------------------------------------------------------------------
echo
echo "[+] Creando enlaces simbólicos en /usr/local/bin..."

for bin in openshift-install oc kubectl; do
    if [ -f "/opt/bin/$bin" ]; then
        sudo ln -sf "/opt/bin/$bin" "/usr/local/bin/$bin"
        echo "   → /usr/local/bin/$bin enlazado"
    else
        echo "   ⚠ No existe /opt/bin/$bin (¿Instalado correctamente?)"
    fi
done

# --------------------------------------------------------------------
# 3) Configurar kubeconfig
# --------------------------------------------------------------------
echo
echo "[+] Configurando kubeconfig..."

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
    echo "    Ejecuta deploy.sh antes."
    exit 1
fi

echo "✔ kubeconfig configurado correctamente."

# --------------------------------------------------------------------
# 4) Verificación
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
echo "[*] Probando conexión al cluster (oc whoami):"
oc whoami || echo "⚠ Aún no hay conexión al cluster (bootstrap/master no listos)"

echo
echo "==============================================="
echo "  kubeconfig de OKD configurado. Entorno listo."
echo "==============================================="
