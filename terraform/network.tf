# terraform/network.tf

resource "libvirt_network" "okd_net" {
  name      = var.network_name
  autostart = true

  # Bridge de la red
  bridge = {
    name = "virbr_okd"
  }

  # Dominio DNS del cluster
  domain = {
    name = "${var.cluster_name}.${var.cluster_domain}"
    local_only = "yes"
  }

  # Configuración de IP y DHCP
  ips = [{
    family  = "ipv4"
    address = cidrhost(var.network_cidr, 1)  # Ej: 10.56.0.1
    netmask = cidrnetmask(var.network_cidr)

    dhcp = {
      hosts = [
        {
          mac  = var.bootstrap.mac
          ip   = var.bootstrap.ip
          name = "bootstrap"
        },
        {
          mac  = var.master.mac
          ip   = var.master.ip
          name = "master"
        },
        {
          mac  = var.worker.mac
          ip   = var.worker.ip
          name = "worker"
        },
        {
          mac  = var.infra.mac
          ip   = var.infra.ip
          name = "infra"
        }
      ]
    }
  }]

  # DNS embebido de libvirt
  dns = {
    host = [
      {
        ip = var.infra.ip
        hostnames = [
          { hostname = "infra" }
        ]
      }
    ]

    forwarders = [
      {
        addr = var.infra_ip  # Forward hacia CoreDNS del nodo infra
      }
    ]
  }
}
