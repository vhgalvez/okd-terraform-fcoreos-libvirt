# terraform/network.tf
resource "libvirt_network" "okd_net" {
  name      = var.network_name
  mode      = "nat"
  bridge    = "virbr_okd"

  # Dominio real del cluster → okd.okd.local
  domain    = "${var.cluster_name}.${var.cluster_domain}"

  addresses = [var.network_cidr]
  autostart = true

  dhcp {
    enabled = true
  }

  dns {
    enabled    = true
    local_only = false

    forwarders {
      # CoreDNS interno (IP fija del nodo infra)
      address = var.infra_ip
    }
  }
}