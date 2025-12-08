# terraform\network.tf
# terraform\network.tf
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
    
    # 1. Definición del primer forwarder (var.dns1)
    forwarder {
      addr = var.dns1
    }
    
    # 2. Definición del segundo forwarder (var.dns2)
    forwarder {
      addr = var.dns2
    }
    
    # Puedes añadir aquí también bloques 'host' si necesitas registros DNS estáticos.
  }
}