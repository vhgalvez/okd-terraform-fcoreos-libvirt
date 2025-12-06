# terraform/network.tf

resource "libvirt_network" "okd_net" {
  name      = var.network_name
  mode      = "nat"
  bridge    = "virbr_okd"
  domain    = var.cluster_domain
  addresses = [var.network_cidr]
  autostart = true

  dhcp {
    enabled = true
  }

  dns {
    enabled    = true
    local_only = false

    forwarders {
      address = "10.56.0.10"
    }
  }
}