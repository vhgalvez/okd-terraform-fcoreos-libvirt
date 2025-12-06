#!/usr/bin/env bash
# ============================================================
#  destroy_bootstrap.sh
#  Elimina correctamente el nodo BOOTSTRAP de OKD 4.x en libvirt
# ============================================================

set -euo pipefail

VM_NAME="okd-bootstrap"

echo "=============================================="
echo "  ELIMINANDO BOOTSTRAP DE OKD 4.x"
echo "=============================================="
echo ""

# Verificar si existe
if ! sudo virsh dominfo "$VM_NAME" &>/dev/null; then
    echo "❌ La máquina virtual '$VM_NAME' no existe. Nada que eliminar."
    exit 0
fi

echo "🔍 VM encontrada: $VM_NAME"
echo ""

# Apagar la VM si está corriendo
if sudo virsh domstate "$VM_NAME" | grep -q running; then
    echo "⏹ Apagando VM bootstrap..."
    sudo virsh destroy "$VM_NAME"
else
    echo "ℹ️  La VM ya está apagada."
fi

# Borrar definición y discos
echo "🗑 Eliminando definición y discos asociados..."
sudo virsh undefine "$VM_NAME" --remove-all-storage

echo ""
echo "=============================================="
echo "✔ BOOTSTRAP ELIMINADO COMPLETAMENTE"
echo "=============================================="
echo "Ahora el master continúa la instalación de forma normal."
