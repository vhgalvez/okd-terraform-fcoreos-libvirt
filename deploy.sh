#!/bin/bash
set -e

echo "[1/5] Generando Ignition..."
openshift-install create ignition-configs --dir=install-config

echo "[2/5] Copiando Ignition a carpeta ./ignition/"
sudo mkdir -p ignition
sudo cp install-config/*.ign ignition/

echo "[3/5] Aplicando Terraform..."
cd terraform
sudo terraform init
sudo terraform apply -auto-approve
cd ..

echo "[4/5] Mostrando IPs del cluster:"
sudo terraform -chdir=terraform output

echo "[5/5] Instalación completada."
