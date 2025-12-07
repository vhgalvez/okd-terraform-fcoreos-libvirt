# terraform/main.tf

#############################################
#            TERRAFORM CONFIG
#############################################
terraform {
  required_version = ">= 1.10.0, < 2.0.0"

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

#############################################
#              PROVIDERS
#############################################
provider "libvirt" {
  uri = "qemu:///system"
}

#############################################
#         LIBVIRT POOL (NUEVA SINTAXIS)
#############################################
resource "libvirt_pool" "okd" {
  name   = "okd"
  type   = "dir"

  # En 0.9.1 se usa target = "ruta" (NO block)
  target = "/var/lib/libvirt/images/okd"
}

#############################################
#               OUTPUTS
#############################################
output "pool_okd_path" {
  value = libvirt_pool.okd.target
}
