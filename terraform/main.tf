# terraform/main.tf
# ============================
# CONFIGURACIÓN DEL BACKEND
# ============================

terraform {
  required_version = ">= 1.14.1, < 2.0.0"

  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.8.3"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.2.0"
    }
  }
}


# ============================
# PROVEEDORES
# ============================

provider "libvirt" {
  uri = "qemu:///system"
}

# ============================
# LIBVIRT POOL (CONFIGURACIÓN)
# ============================

resource "libvirt_pool" "okd" {
  name   = "okd"
  type   = "dir"
  target = "/var/lib/libvirt/images/okd"
}

# ============================
# OUTPUTS
# ============================

output "pool_okd_path" {
  value = libvirt_pool.okd.target
}
