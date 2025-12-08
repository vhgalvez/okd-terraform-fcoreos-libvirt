# terraform/main.tf
########################################################################
# TERRAFORM + PROVIDERS
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

provider "libvirt" {
  uri = "qemu:///system"
}

########################################################################
# STORAGE POOL (SIN WARNINGS)
########################################################################

resource "libvirt_pool" "okd" {
  name = "okd"
  type = "dir"

  target {
    path = "/var/lib/libvirt/images/okd"
  }
}
