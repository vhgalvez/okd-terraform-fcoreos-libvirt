# terraform\network.tf
resource "libvirt_network" "okd_net" {
  name      = var.network_name
  mode      = "nat"
  domain    = "${var.cluster_name}.${var.cluster_domain}"

  addresses = [var.network_cidr]
  autostart = true

  dhcp {
    enabled = true
  }

  dns {
    enabled = true
  }
}
