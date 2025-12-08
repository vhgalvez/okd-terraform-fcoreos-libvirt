resource "libvirt_network" "okd_net" {
  name   = var.network_name
  mode   = "nat"
  domain = "${var.cluster_name}.${var.cluster_domain}"

  addresses = [var.network_cidr]
  autostart = true

  dhcp {
    enabled = true
  }

  dns {
    enabled = true

    forwarders = [
      { addr = var.infra_ip }
    ]

    hosts = [
      {
        hostname = "infra"
        ip       = var.infra.ip
      }
    ]
  }
}
