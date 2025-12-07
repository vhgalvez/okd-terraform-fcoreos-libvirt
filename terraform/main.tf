# terraform/main.tf
#############################################
#            TERRAFORM CONFIG
#############################################
terraform {
  required_version = ">= 1.10.0, < 2.0.0"

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

#############################################
#              PROVIDERS
#############################################
provider "libvirt" {
  uri = "qemu:///system"
}

#############################################
#         LIBVIRT POOL PARA OKD
#    Almacenará discos e Ignitions
#############################################
resource "libvirt_pool" "okd" {
  name = "okd"
  type = "dir"

  # Reemplazo correcto para path (evita warning)
  target {
    path = "/var/lib/libvirt/images/okd"
  }

  lifecycle {
    create_before_destroy = true
  }
}

#############################################
#           OPTIONAL OUTPUTS
#############################################
output "pool_okd_path" {
  value = libvirt_pool.okd.target[0].path
}
