# terraform/network.tf

resource "libvirt_network" "okd_net" {
  name      = var.network_name       # "okd-net"
  mode      = "nat"
  bridge    = "virbr_okd"
  domain    = "okd-lab.cefaslocalserver.com"
  addresses = [var.network_cidr]     # "10.56.0.0/24"
  autostart = true

  dhcp {
    enabled = true
  }

  # DNS de libvirt (10.56.0.1) → reenvía TODO a infra (10.56.0.10)
  dns {
    enabled    = true
    local_only = false

    forwarders {
      address = "10.56.0.10"   # VM infra con CoreDNS
    }
  }
}
