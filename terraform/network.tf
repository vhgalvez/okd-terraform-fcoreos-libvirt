# terraform/network.tf
resource "libvirt_network" "okd_net" {
  name      = var.network_name          # Ej: "okd-net"
  mode      = "nat"
  bridge    = "virbr_okd"               # Nombre del puente que creará libvirt
  domain    = "okd.internal"
  autostart = true

  # CIDR definido en terraform.tfvars: "10.17.3.0/24"
  addresses = [var.network_cidr]

  # DHCP habilitado (aunque todas tus VMs lleven IP estática)
  dhcp {
    enabled = true
  }

  # Habilita dnsmasq interno de libvirt
  dns {
    enabled    = true
    local_only = false
  }
}
