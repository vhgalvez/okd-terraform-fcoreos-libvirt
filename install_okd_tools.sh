#!/usr/bin/env bash
set -euo pipefail

echo "==============================================="
echo "  Instalador de herramientas OKD / OpenShift"
echo "==============================================="

# --- CONFIG ---
OKD_CLIENT_URL="https://github.com/okd-project/okd/releases/download/4.12.0-0.okd-2023-01-21-042244/openshift-client-linux-4.12.0-0.okd-2023-01-21-042244.tar.gz"
OKD_CLIENT_SHA256="c4dc1095c7e4d0e323d263e662f839d21f63d3e0282c35cddb1f2a802908896f"

OKD_INSTALLER_URL="https://github.com/okd-project/okd/releases/download/4.12.0-0.okd-2023-01-21-042244/openshift-install-linux-4.12.0-0.okd-2023-01-21-042244.tar.gz"
OKD_INSTALLER_SHA256="cc1ed09f796d5fc5bebae30a3f1c3e039c6229c1de4a12dfea59c7ea93a7e8a3"

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
echo "✔ Hash del cliente verificado."

echo "[+] Extrayendo oc y kubectl..."
tar -xzf openshift-client-linux.tar.gz oc kubectl

echo "[+] Instalando oc y kubectl en ${BIN_DIR}"
sudo mv -f oc kubectl "$BIN_DIR/"
sudo chmod +x "$BIN_DIR/oc" "$BIN_DIR/kubectl"

echo "[+] Cliente instalado:"
"$BIN_DIR/oc" version --client || true

# Asegurar PATH
if ! grep -q "export PATH=/opt/bin:\$PATH" "$HOME/.bashrc"; then
    echo "[+] Añadiendo /opt/bin al PATH en ~/.bashrc"
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
echo "✔ Hash del instalador verificado."

echo "[+] Extrayendo openshift-install..."
tar -xzf openshift-install-linux.tar.gz openshift-install

echo "[+] Instalando openshift-install en ${BIN_DIR}"
sudo mv -f openshift-install "$BIN_DIR/"
sudo chmod +x "$BIN_DIR/openshift-install"

echo "[+] Versión del instalador:"
"$BIN_DIR/openshift-install" version || true

# ================================================================
# --- VERIFICACIÓN FINAL ---
# ================================================================
echo
echo "==============================================="
echo "  Verificación final (binarios OKD)"
echo "==============================================="

echo -n "[*] oc disponible... "
command -v oc >/dev/null 2>&1 && echo "✔" || echo "❌"

echo -n "[*] kubectl disponible... "
command -v kubectl >/dev/null 2>&1 && echo "✔" || echo "❌"

echo -n "[*] openshift-install disponible... "
command -v openshift-install >/dev/null 2>&1 && echo "✔" || echo "❌"

echo "[*] Verificando ejecución de oc..."
oc version --client && echo "✔ oc funciona" || echo "⚠ oc funciona pero no hay cluster"

echo "[*] Verificando ejecución de openshift-install..."
openshift-install version && echo "✔ openshift-install funciona" || echo "❌ ERROR"

echo
echo "==============================================="
echo "  Herramientas OKD instaladas correctamente."
echo "  Ahora puedes generar Ignition y crear el clúster."
echo "==============================================="