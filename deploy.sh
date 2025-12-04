#!/bin/bash
set -e

echo "[1/5] Generando Ignition..."
openshift-install create ignition-configs --dir=install-config

echo "[2/5] Copiando Ignition a carpeta ./ignition/"
mkdir -p ignition
cp install-config/*.ign ignition/

echo "[3/5] Aplicando Terraform..."
cd terraform
terraform init
terraform apply -auto-approve
cd ..

echo "[4/5] Mostrando IPs del cluster:"
terraform -chdir=terraform output

echo "[5/5] Instalación completada."
