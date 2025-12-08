# terraform/main.tf
########################################################################
# TERRAFORM BACKEND + PROVIDERS
########################################################################

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

########################################################################
# PROVIDER LIBVIRT
########################################################################

provider "libvirt" {
  uri = "qemu:///system"
}

########################################################################
# STORAGE POOL (SINTAXIS 0.8.3)
# - path es atributo directo
########################################################################

resource "libvirt_pool" "okd" {
  name = "okd"
  type = "dir"
  path = "/var/lib/libvirt/images/okd"
}
