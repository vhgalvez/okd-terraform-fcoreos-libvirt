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
    
    # Esta es la sintaxis requerida por la versión 0.8.3.
    forwarders = [
      { addr = var.dns1 },
      { addr = var.dns2 }
    ]
    
    # OPCIONAL: Ejemplo de cómo agregar un registro estático para 'infra'
    /*
    host {
      ip        = var.infra.ip
      hostnames = ["infra", "infra.${var.cluster_name}.${var.cluster_domain}"]
    }
    */
  }
}