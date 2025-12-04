resource "libvirt_network" "okd" {
  name      = var.network_name
  mode      = "nat"
  domain    = "cefaslocalserver.com"
  addresses = [var.network_cidr]

  dhcp {
    enabled = false
  }

  dns {
    enabled = true
  }

  autostart = true
}
