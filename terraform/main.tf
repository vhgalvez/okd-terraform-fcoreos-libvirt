# terraform/main.tf

# terraform/main.tf
########################################################################
# TERRAFORM BACKEND + PROVIDERS
########################################################################

terraform {
  required_version = ">= 1.14.1, < 2.0.0"

  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.9.1"
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
# STORAGE POOL (SINTAXIS CORREGIDA PARA 0.9.1) 🛠️
########################################################################

resource "libvirt_pool" "okd" {
  name = "okd"
  type = "dir"

  # ✅ CORREGIDO: Se elimina el bloque 'target' y se usa el argumento 'path'
  # directamente dentro del recurso libvirt_pool.
  path = "/var/lib/libvirt/images/okd"
}

########################################################################
# OUTPUTS (SINTAXIS CORREGIDA PARA 0.9.1) 🛠️
########################################################################

output "pool_okd_path" {
  # ✅ CORREGIDO: El path ya no está en el atributo target.path, sino en .path
  value       = libvirt_pool.okd.path
  description = "Ruta real del pool OKD"
}