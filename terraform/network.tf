# terraform\network.tf
###########################################################
# RED OKD SIN DHCP (modo route = IPs fijas 100% funcionales)
###########################################################

resource "libvirt_network" "okd_net" {
  name      = var.network_name
  mode      = "route"   # ← SOLUCIÓN DEFINITIVA PARA IP FIJA
  domain    = "${var.cluster_name}.${var.cluster_domain}"

  # Rango de red
  addresses = [var.network_cidr]

  autostart = true

  # DNS interno (opcional)
  dns {
    enabled = true
  }
}
