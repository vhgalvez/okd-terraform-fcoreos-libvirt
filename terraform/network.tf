# terraform/network.tf
resource "libvirt_network" "okd_net" {
  name      = var.network_name
  mode      = "nat"
  bridge    = "virbr_okd"
  domain    = "${var.cluster_name}.${var.cluster_domain}"
  autostart = true
  addresses = [var.network_cidr]

  dhcp {
    enabled = true
  }

  dns {
    enabled = true

    # 👉 Todo lo que reciban las VMs se reenvía a infra (CoreDNS)
    forwarders {
      address = var.infra.ip   # 10.56.0.10
    }
  }
}
