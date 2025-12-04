#!/usr/bin/env bash
set -euo pipefail

echo "==============================================="
echo "  Instalador de herramientas OKD / OpenShift"
echo "==============================================="

# --- CONFIG ---
OC_URL="https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz"
OKD_URL="https://github.com/okd-project/okd/releases/download/4.21.0-okd-scos.ec.9/openshift-install-linux-4.21.0-okd-scos.ec.9.tar.gz"
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

# Descargar OC CLI
echo "[+] Descargando oc CLI..."
sudo curl -L -o /tmp/oc.tar.gz "$OC_URL"

echo "[+] Descomprimiendo..."
tar -xzf /tmp/oc.tar.gz -C /tmp

echo "[+] Moviendo a ${BIN_DIR}"
sudo mv /tmp/oc "$BIN_DIR/oc"
sudo chmod +x "$BIN_DIR/oc"

# --- Export PATH ---
if ! echo "$PATH" | grep -q "$BIN_DIR"; then
    echo "[+] Añadiendo ${BIN_DIR} al PATH"
    echo "export PATH=\$PATH:$BIN_DIR" >> ~/.bashrc
    export PATH=$PATH:$BIN_DIR
fi

echo "[+] oc instalado correctamente:"
oc version || echo "oc instalado pero sin conexión a cluster"


echo
echo "==============================================="
echo "  Instalando OKD Installer 4.14.0"
echo "==============================================="

cd /tmp

echo "[+] Descargando instalador OKD..."
wget -q "$OKD_URL" -O /tmp/openshift-install.tar.gz

echo "[+] Descomprimiendo instalador..."
tar -xzvf /tmp/openshift-install.tar.gz

echo "[+] Moviendo a ${BIN_DIR}"
sudo mv openshift-install "$BIN_DIR/"
sudo chmod +x "$BIN_DIR/openshift-install"

echo "[+] Comprobando versión:"
openshift-install version || true

echo
echo "==============================================="
echo "  Instalación completada!"
echo "  - oc en: $BIN_DIR/oc"
echo "  - openshift-install en: $BIN_DIR/openshift-install"
echo "  Recarga tu terminal o ejecuta: source ~/.bashrc"
echo "==============================================="
