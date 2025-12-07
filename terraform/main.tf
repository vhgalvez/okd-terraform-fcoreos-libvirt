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

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_pool" "okd" {
  name   = "okd"
  type   = "dir"
  target = "/var/lib/libvirt/images/okd"
}

output "pool_okd_path" {
  value = libvirt_pool.okd.target
}
