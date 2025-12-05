# terraform/network.tf
resource "libvirt_network" "okd_net" {
  name      = var.network_name                 # ej: "okd-net"
  mode      = "nat"
  bridge    = "virbr_okd"                      # puente dedicado, libvirt lo crea
  domain    = "okd.internal"
  autostart = true

  # Rango de red, ej: "10.17.3.0/24"
  addresses = [var.network_cidr]

  # IMPORTANTE: habilitar DHCP aunque vayas a usar IPs estáticas
  dhcp {
    enabled = true
  }

  # ACTIVAR DNSMASQ
  dns {
    enabled    = true        # activa dnsmasq interno de libvirt
    local_only = false       # permite reenviar consultas hacia fuera
  }

  # MEGA IMPORTANTE: NAT EXPLÍCITO PARA SALIDA A INTERNET
  iptables {
    ipv4_nat = true
  }
}
