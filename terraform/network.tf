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
