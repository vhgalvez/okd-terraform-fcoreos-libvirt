#!/usr/bin/env bash
set -euo pipefail

echo "==============================================="
echo "  Instalador de herramientas OKD / OpenShift"
echo "==============================================="


# --- CONFIG ---
OKD_CLIENT_URL="https://github.com/okd-project/okd/releases/download/4.19.0-okd-scos.9/openshift-client-linux-4.19.0-okd-scos.9.tar.gz"
OKD_CLIENT_SHA256="ddf3b97db74d7eb4961699a249f36a47b3989e12e0352cf66acfec194d3bc241"

OKD_INSTALLER_URL="https://github.com/okd-project/okd/releases/download/4.19.0-okd-scos.9/openshift-install-linux-4.19.0-okd-scos.9.tar.gz"
OKD_INSTALLER_SHA256="1f675e79eca69686d423af1e1bb5faf4629cdf56ee5bb71b3beed6811523afcb"


BIN_DIR="/opt/bin"
TMP_CLIENT="/tmp/okd-client"
TMP_INSTALL="/tmp/okd-installer"

# --- PREPARAR DIRECTORIOS ---

echo "[+] Creando directorio de binarios: ${BIN_DIR}"
sudo mkdir -p "$BIN_DIR"

echo "[+] Limpiando y creando directorios temporales..."
sudo rm -rf "$TMP_CLIENT" "$TMP_INSTALL"
mkdir -p "$TMP_CLIENT" "$TMP_INSTALL"

# --- INSTALAR CLIENTE (oc + kubectl) ---

echo
echo "==============================================="
echo "  Instalando OpenShift Client (oc + kubectl)"
echo "==============================================="

cd "$TMP_CLIENT"

echo "[+] Descargando cliente OKD..."
wget -q "$OKD_CLIENT_URL" -O openshift-client-linux.tar.gz

echo "[+] Verificando SHA256 del cliente..."
SHA_ACTUAL_CLIENT=$(sha256sum openshift-client-linux.tar.gz | awk '{print $1}')
echo "  - Esperado: $OKD_CLIENT_SHA256"
echo "  - Actual:   $SHA_ACTUAL_CLIENT"

if [[ "$SHA_ACTUAL_CLIENT" != "$OKD_CLIENT_SHA256" ]]; then
    echo "❌ ERROR: Hash SHA256 del cliente NO coincide"
    exit 1
fi
echo "✔ Hash del cliente verificado correctamente."

echo "[+] Extrayendo SOLO oc y kubectl..."
tar -xzf openshift-client-linux.tar.gz oc kubectl

echo "[+] Instalando oc y kubectl en ${BIN_DIR}"
sudo mv -f oc kubectl "$BIN_DIR/"
sudo chmod +x "$BIN_DIR/oc" "$BIN_DIR/kubectl"

echo "[+] Cliente instalado:"
"$BIN_DIR/oc" version --client || true

# Asegurar que /opt/bin esté al principio del PATH
if ! grep -q "export PATH=/opt/bin:\$PATH" "$HOME/.bashrc"; then
    echo "[+] Añadiendo /opt/bin al PATH en ~/.bashrc (al inicio)"
    echo 'export PATH=/opt/bin:$PATH' >> "$HOME/.bashrc"
fi
export PATH=/opt/bin:$PATH

echo "[+] Ruta actual de oc:"
command -v oc || true

# --- INSTALAR INSTALLER ---

echo
echo "==============================================="
echo "  Instalando OKD Installer"
echo "==============================================="

cd "$TMP_INSTALL"

echo "[+] Descargando instalador..."
wget -q "$OKD_INSTALLER_URL" -O openshift-install-linux.tar.gz

echo "[+] Verificando SHA256 del instalador..."
SHA_ACTUAL_INSTALL=$(sha256sum openshift-install-linux.tar.gz | awk '{print $1}')
echo "  - Esperado: $OKD_INSTALLER_SHA256"
echo "  - Actual:   $SHA_ACTUAL_INSTALL"

if [[ "$SHA_ACTUAL_INSTALL" != "$OKD_INSTALLER_SHA256" ]]; then
    echo "❌ ERROR: Hash SHA256 del instalador NO coincide"
    exit 1
fi
echo "✔ Hash del instalador verificado correctamente."

echo "[+] Extrayendo SOLO openshift-install..."
tar -xzf openshift-install-linux.tar.gz openshift-install

echo "[+] Instalando openshift-install en ${BIN_DIR}"
sudo mv -f openshift-install "$BIN_DIR/"
sudo chmod +x "$BIN_DIR/openshift-install"

echo "[+] Versión del instalador:"
"$BIN_DIR/openshift-install" version || true

echo
echo "==============================================="
echo "  Instalación completada!"
echo "  - oc              → /opt/bin/oc"
echo "  - kubectl         → /opt/bin/kubectl"
echo "  - openshift-install → /opt/bin/openshift-install"
echo
echo "Recarga tu entorno de shell con:"
echo "   source ~/.bashrc"
echo "==============================================="
