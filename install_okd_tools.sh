#!/usr/bin/env bash
set -euo pipefail

echo "==============================================="
echo "  Instalador de herramientas OKD / OpenShift"
echo "==============================================="

# --- CONFIG ---
OKD_CLIENT_URL="https://github.com/okd-project/okd/releases/download/4.21.0-okd-scos.ec.9/openshift-client-linux-4.21.0-okd-scos.ec.9.tar.gz"
OKD_CLIENT_SHA256="0277386921fdb2fdfd26800704324b393747c5b3159c70bcb9c0179572bc756a"

OKD_INSTALLER_URL="https://github.com/okd-project/okd/releases/download/4.21.0-okd-scos.ec.9/openshift-install-linux-4.21.0-okd-scos.ec.9.tar.gz"
OKD_INSTALLER_SHA256="962291fbba69b7d7bedae4573c9210a4d5692607199e46fd6bde5543653c4bd3"

BIN_DIR="/opt/bin"

# Crear directorio
if [[ ! -d "$BIN_DIR" ]]; then
    echo "[+] Creando ${BIN_DIR}"
    sudo mkdir -p "$BIN_DIR"
fi

echo
echo "==============================================="
echo "  Instalando OpenShift Client (oc + kubectl)"
echo "==============================================="

cd /tmp
rm -f openshift-client-linux.tar.gz oc kubectl

echo "[+] Descargando cliente OKD..."
wget -q "$OKD_CLIENT_URL" -O openshift-client-linux.tar.gz

echo "[+] Verificando SHA256..."
SHA_ACTUAL=$(sha256sum openshift-client-linux.tar.gz | awk '{print $1}')
echo "  - Esperado: $OKD_CLIENT_SHA256"
echo "  - Actual:   $SHA_ACTUAL"

if [[ "$SHA_ACTUAL" != "$OKD_CLIENT_SHA256" ]]; then
    echo "❌ ERROR: Hash SHA256 NO coincide"
    exit 1
fi
echo "✔ Hash verificado correctamente."

echo "[+] Extrayendo oc y kubectl..."
tar -xzf openshift-client-linux.tar.gz --overwrite

echo "[+] Instalando en ${BIN_DIR}"
sudo mv oc kubectl "$BIN_DIR/"
sudo chmod +x "$BIN_DIR/oc" "$BIN_DIR/kubectl"

echo "[+] Cliente instalado:"
"$BIN_DIR/oc" version --client

# Añadir PATH si falta
if ! echo "$PATH" | grep -q "$BIN_DIR"; then
    echo "export PATH=\$PATH:$BIN_DIR" >> ~/.bashrc
    export PATH=$PATH:$BIN_DIR
fi

echo
echo "==============================================="
echo "  Instalando OKD Installer"
echo "==============================================="

rm -f openshift-install-linux.tar.gz openshift-install

echo "[+] Descargando instalador..."
wget -q "$OKD_INSTALLER_URL" -O openshift-install-linux.tar.gz

echo "[+] Verificando SHA256 del instalador..."
SHA_ACTUAL=$(sha256sum openshift-install-linux.tar.gz | awk '{print $1}')
echo "  - Esperado: $OKD_INSTALLER_SHA256"
echo "  - Actual:   $SHA_ACTUAL"

if [[ "$SHA_ACTUAL" != "$OKD_INSTALLER_SHA256" ]]; then
    echo "❌ ERROR: Hash SHA256 NO coincide"
    exit 1
fi
echo "✔ Hash verificado correctamente."

echo "[+] Extrayendo openshift-install..."
tar -xzf openshift-install-linux.tar.gz --overwrite

echo "[+] Moviendo a ${BIN_DIR}"
sudo mv openshift-install "$BIN_DIR/"
sudo chmod +x "$BIN_DIR/openshift-install"

"$BIN_DIR/openshift-install" version

echo
echo "==============================================="
echo "  Instalación completada!"
echo "  - oc en: /opt/bin/oc"
echo "  - kubectl en: /opt/bin/kubectl"
echo "  - openshift-install en: /opt/bin/openshift-install"
echo
echo "Recarga tu terminal:"
echo "   source ~/.bashrc"
echo "==============================================="
