# terraform/network.tf

resource "libvirt_network" "okd_net" {
  name      = var.network_name
  mode      = "nat"
  bridge    = "virbr_okd"
  domain    = "okd.internal"
  autostart = true
  addresses = ["${var.network_cidr}"]

  dhcp {
    enabled = true
  }
}

resource "libvirt_pool" "okd_pool" {
  name = "okd"        # nombre correcto del pool
  type = "dir"

  target {
    path = "/var/lib/libvirt/images/okd"
  }
}
