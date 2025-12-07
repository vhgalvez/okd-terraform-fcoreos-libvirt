# terraform/network.tf
resource "libvirt_network" "okd_net" {
  name = var.network_name
  mode = "nat"

  bridge = {
    name = "virbr_okd"
  }

  domain = {
    name = "${var.cluster_name}.${var.cluster_domain}"
  }

  addresses = [{
    address = var.network_cidr
  }]

  autostart = true

  #############################################
  # DHCP — Sintaxis nueva completa (libvirt 0.9.1)
  #############################################
  dhcp = {
    enabled = true

    hosts = [
      {
        mac  = var.bootstrap.mac
        name = "bootstrap"
        ip   = var.bootstrap.ip
      },
      {
        mac  = var.master.mac
        name = "master"
        ip   = var.master.ip
      },
      {
        mac  = var.worker.mac
        name = "worker"
        ip   = var.worker.ip
      },
      {
        mac  = var.infra.mac
        name = "infra"
        ip   = var.infra.ip
      }
    ]
  }

  #############################################
  # DNS FORWARDER → redirige al nodo infra
  #############################################
  dns = {
    enabled    = true
    local_only = false
    forwarders = [{
      address = var.infra_ip
    }]
  }
}
