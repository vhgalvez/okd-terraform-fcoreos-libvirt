#!/usr/bin/env bash
set -euo pipefail

echo "==============================================="
echo "  Instalador de herramientas OKD / OpenShift"
echo "==============================================="

# --- CONFIG ---
OC_URL="https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz"
OKD_URL="https://github.com/okd-project/okd/releases/download/4.21.0-okd-scos.ec.9/openshift-install-linux-4.21.0-okd-scos.ec.9.tar.gz"
OKD_SHA256_EXPECTED="962291fbba69b7d7bedae4573c9210a4d5692607199e46fd6bde5543653c4bd3"
BIN_DIR="/opt/bin"

# Crear directorio si no existe
if [[ ! -d "$BIN_DIR" ]]; then
    echo "[+] Creando ${BIN_DIR}"
    sudo mkdir -p "$BIN_DIR"
fi

echo
echo "==============================================="
echo "  Instalando OpenShift Client (oc)"
echo "==============================================="

echo "[+] Descargando oc CLI..."
sudo curl -L -o /tmp/oc.tar.gz "$OC_URL"

echo "[+] Descomprimiendo oc (solo binario oc)..."
tar -xzf /tmp/oc.tar.gz -C /tmp oc

echo "[+] Moviendo oc a ${BIN_DIR}"
sudo mv /tmp/oc "$BIN_DIR/oc"
sudo chmod +x "$BIN_DIR/oc"

# Añadir PATH
if ! echo "$PATH" | grep -q "$BIN_DIR"; then
    echo "[+] Añadiendo ${BIN_DIR} al PATH"
    echo "export PATH=\$PATH:$BIN_DIR" >> ~/.bashrc
    export PATH=$PATH:$BIN_DIR
fi

echo "[+] oc instalado correctamente:"
oc version || echo "oc instalado pero sin conexión al cluster"


echo
echo "==============================================="
echo "  Instalando OKD Installer 4.21.0"
echo "==============================================="

cd /tmp

echo "[+] Descargando instalador OKD..."
wget -q "$OKD_URL" -O /tmp/openshift-install.tar.gz

echo "[+] Verificando SHA256..."
OKD_SHA256_ACTUAL=$(sha256sum /tmp/openshift-install.tar.gz | awk '{print $1}')

echo "  - Esperado: $OKD_SHA256_EXPECTED"
echo "  - Actual:   $OKD_SHA256_ACTUAL"

if [[ "$OKD_SHA256_ACTUAL" != "$OKD_SHA256_EXPECTED" ]]; then
    echo "❌ ERROR: verificación SHA256 FALLÓ"
    echo "   El archivo está corrupto o fue modificado."
    exit 1
else
    echo "✔ Hash SHA256 verificado correctamente."
fi

echo "[+] Descomprimiendo instalador..."
tar -xzvf /tmp/openshift-install.tar.gz

echo "[+] Moviendo openshift-install a ${BIN_DIR}"
sudo mv openshift-install "$BIN_DIR/"
sudo chmod +x "$BIN_DIR/openshift-install"

echo
echo "[+] Comprobando versión de openshift-install:"
openshift-install version

echo
echo "==============================================="
echo "  Instalación completada!"
echo "  - oc en: $BIN_DIR/oc"
echo "  - openshift-install en: $BIN_DIR/openshift-install"
echo
echo "  Recarga tu terminal con:"
echo "     source ~/.bashrc"
echo "==============================================="