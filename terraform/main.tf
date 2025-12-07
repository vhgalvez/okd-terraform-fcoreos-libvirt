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
# STORAGE POOL (SINTAXIS CORRECTA PARA 0.9.1)
########################################################################

resource "libvirt_pool" "okd" {
  name = "okd"
  type = "dir"

  # ✔ target debe ser BLOQUE, NO string
  target {
    path = "/var/lib/libvirt/images/okd"
  }
}

########################################################################
# OUTPUTS
########################################################################

output "pool_okd_path" {
  value       = libvirt_pool.okd.target.path
  description = "Ruta real del pool OKD"
}
