# terraform/main.tf
########################################################################
# TERRAFORM BACKEND + PROVIDERS
########################################################################

terraform {
  required_version = ">= 1.14.1, < 2.0.0"

  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.9.1" # Versión deseada
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.2.0"
    }
  }
}

########################################################################
# PROVIDER LIBVIRT
########################################################################

provider "libvirt" {
  uri = "qemu:///system"
}

########################################################################
# STORAGE POOL
########################################################################

resource "libvirt_pool" "okd" {
  name = "okd"
  type = "dir"

  # ✅ CORRECCIÓN: Volvemos al bloque 'target {}', ya que el último error (`target = "..."`) exigió un objeto (mapa).
  target {
    path = "/var/lib/libvirt/images/okd"
  }
}

########################################################################
# OUTPUTS
########################################################################

output "pool_okd_path" {
  # ✅ CORRECCIÓN: El valor se extrae del bloque target.path.
  value       = libvirt_pool.okd.target.path
  description = "Ruta real del pool OKD"
}