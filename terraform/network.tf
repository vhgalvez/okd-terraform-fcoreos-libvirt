# terraform/network.tf
resource "libvirt_network" "okd_net" {
  name   = var.network_name
  mode   = "nat"
  bridge = "virbr_okd"

  # Dominio REAL del cluster
  domain = "${var.cluster_name}.${var.cluster_domain}" # okd.okd.local

  addresses = [var.network_cidr]
  autostart = true

  dhcp {
    enabled = true # Puede quedar así, no molesta
  }

  dns {
    enabled    = true
    local_only = false

    forwarders {
      # CoreDNS interno
      address = var.infra.ip # 10.56.0.10
    }
  }
}
