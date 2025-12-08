#!/usr/bin/env bash

# scripts/install_okd_tools.sh
set -euo pipefail

echo "==============================================="
echo "  Instalador de herramientas OKD / OpenShift"
echo "==============================================="

# ------------------------------------------------
# CONFIGURACIÓN: SOLO MODIFICAR ESTA VARIABLE
# ------------------------------------------------
# 4.13.0-0.okd-2023-10-28-065448

OKD_TAG="4.12.0-0.okd-2023-04-16-041331"

BASE_URL="https://github.com/okd-project/okd/releases/download/${OKD_TAG}"

CLIENT_FILE="openshift-client-linux-${OKD_TAG}.tar.gz"
INSTALL_FILE="openshift-install-linux-${OKD_TAG}.tar.gz"

BIN_DIR="/opt/bin"
TMP_DIR="/tmp/okd-tools"

# ------------------------------------------------
# Preparación de directorios
# ------------------------------------------------
echo "[+] Preparando entorno..."
sudo mkdir -p "$BIN_DIR"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"
cd "$TMP_DIR"

echo "[+] Descargando sha256sum oficial..."
wget -q "${BASE_URL}/sha256sum.txt" -O sha256sum.txt

if [[ ! -s sha256sum.txt ]]; then
    echo "❌ ERROR: No se pudo descargar sha256sum.txt"
    exit 1
fi

# ------------------------------------------------
# Función para descargar y validar un archivo
# ------------------------------------------------
download_and_verify() {
    local FILE="$1"
    local URL="$2"
    
    echo ""
    echo "==============================================="
    echo "  Descargando y verificando: $FILE"
    echo "==============================================="
    
    echo "[+] Descargando $FILE ..."
    wget -q "$URL" -O "$FILE"
    
    if [[ ! -s "$FILE" ]]; then
        echo "❌ ERROR: Archivo vacío o no descargado: $FILE"
        exit 1
    fi
    
    echo "[+] Calculando hash SHA256..."
    SHA_ACTUAL=$(sha256sum "$FILE" | awk '{print $1}')
    
    SHA_ESPERADO=$(grep "  $FILE\$" sha256sum.txt | awk '{print $1}')
    
    if [[ -z "$SHA_ESPERADO" ]]; then
        echo "❌ ERROR: No se encontró hash en sha256sum.txt para $FILE"
        exit 1
    fi
    
    echo "  - Esperado: $SHA_ESPERADO"
    echo "  - Actual:   $SHA_ACTUAL"
    
    if [[ "$SHA_ACTUAL" != "$SHA_ESPERADO" ]]; then
        echo "❌ ERROR: Hash SHA256 NO coincide para $FILE"
        exit 1
    fi
    
    echo "✔ Hash verificado correctamente para $FILE"
}

# ------------------------------------------------
# Cliente (oc + kubectl)
# ------------------------------------------------
download_and_verify "$CLIENT_FILE" "${BASE_URL}/${CLIENT_FILE}"

echo "[+] Extrayendo oc y kubectl..."
tar -xzf "$CLIENT_FILE" oc kubectl

echo "[+] Instalando en ${BIN_DIR}..."
sudo mv -f oc kubectl "$BIN_DIR/"
sudo chmod +x "$BIN_DIR/oc" "$BIN_DIR/kubectl"

# ------------------------------------------------
# Installer (openshift-install)
# ------------------------------------------------
download_and_verify "$INSTALL_FILE" "${BASE_URL}/${INSTALL_FILE}"

echo "[+] Extrayendo openshift-install..."
tar -xzf "$INSTALL_FILE" openshift-install

echo "[+] Instalando en ${BIN_DIR}..."
sudo mv -f openshift-install "$BIN_DIR/"
sudo chmod +x "$BIN_DIR/openshift-install"

# ------------------------------------------------
# PATH
# ------------------------------------------------
if ! grep -q "export PATH=/opt/bin:\$PATH" "$HOME/.bashrc"; then
    echo "[+] Añadiendo /opt/bin al PATH en ~/.bashrc"
    echo 'export PATH=/opt/bin:$PATH' >> "$HOME/.bashrc"
fi

export PATH=/opt/bin:$PATH

# ------------------------------------------------
# Verificación final
# ------------------------------------------------
echo ""
echo "==============================================="
echo "  Verificación final"
echo "==============================================="

echo -n "[*] oc disponible... "
command -v oc >/dev/null && echo "✔" || echo "❌"

echo -n "[*] kubectl disponible... "
command -v kubectl >/dev/null && echo "✔" || echo "❌"

echo -n "[*] openshift-install disponible... "
command -v openshift-install >/dev/null && echo "✔" || echo "❌"

echo "[*] Versión oc:"
oc version --client || true

echo "[*] Versión openshift-install:"
openshift-install version || true

echo ""
echo "==============================================="
echo "  OKD instalado correctamente."
echo "==============================================="