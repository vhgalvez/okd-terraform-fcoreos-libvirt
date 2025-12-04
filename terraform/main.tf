# terraform/main.tf
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

provider "libvirt" {
  uri = "qemu:///system"
}

# ================================
#  POOL DE LIBVIRT PARA OKD
# ================================
resource "libvirt_pool" "okd" {
  name = "okd"
  type = "dir"
  path = "/var/lib/libvirt/volumes/okd"

  lifecycle {
    create_before_destroy = true
  }
}