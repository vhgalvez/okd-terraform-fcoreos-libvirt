#!/bin/bash
set -e

echo "Destruyendo infraestructura Terraform..."
terraform -chdir=terraform destroy -auto-approve

echo "Borrando archivos generados..."
rm -rf ignition/*.ign
rm -rf install-config/manifests
rm -rf install-config/openshift

echo "Cluster OKD eliminado."