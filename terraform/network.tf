
# terraform/network.tf

###############################################
# RED OKD (libvirt_network - 0.8.3)
###############################################
resource "libvirt_network" "okd_net" {
  name      = var.network_name
  mode      = "nat"
  domain    = "${var.cluster_name}.${var.cluster_domain}"
  addresses = [var.network_cidr]
  autostart = true

  # DHCP básico activado (sin reservas por MAC en esta versión)
  dhcp {
    enabled = true
  }

  # DNS activado dentro de la red libvirt
  dns {
    enabled = true
  }
}
