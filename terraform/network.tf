# terraform/network.tf

resource "libvirt_network" "okd_net" {
  name      = var.network_name
  autostart = true

  bridge = {
    name = "virbr_okd"
  }

  domain = {
    name = "${var.cluster_name}.${var.cluster_domain}"
  }

  # Dirección del propio bridge + DHCP estático para las VMs
  ips = [{
    address = cidrhost(var.network_cidr, 1)  # 10.56.0.1
    netmask = cidrnetmask(var.network_cidr)
    family  = "ipv4"

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
        addr = var.infra_ip
      }
    ]
  }
}
