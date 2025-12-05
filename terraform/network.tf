# terraform/network.tf

resource "libvirt_network" "okd_net" {
  name      = "okd-net"
  mode      = "nat"
  bridge    = "virbr_okd"
  domain    = "okd.internal"
  autostart = true

  # Nueva red OKD
  addresses = ["10.56.0.0/24"]

  dhcp {
    enabled = true
  }

  # Activar dnsmasq para resolución interna
  dns {
    enabled    = true
    local_only = false
  }
}
