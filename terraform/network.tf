# terraform/network.tf
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

    # 👉 1) Forwarder principal (CoreDNS en INFRA)
    forwarders {
      address = var.dns2   # normalmente 10.56.0.10
    }

    # 👉 2) Forwarder secundario (Google DNS como backup)
    forwarders {
      address = var.dns1   # 8.8.8.8
    }
  }
}
