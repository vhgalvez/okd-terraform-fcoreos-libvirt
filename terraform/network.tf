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

  # IP de la red (nuevo modelo ips)
  ips = [
    {
      family  = "ipv4"
      address = cidrhost(var.network_cidr, 1)   # 10.56.0.1
      netmask = cidrnetmask(var.network_cidr)

      dhcp = {
        hosts = [
          {
            name = "bootstrap"
            mac  = var.bootstrap.mac
            ip   = var.bootstrap.ip
          },
          {
            name = "master"
            mac  = var.master.mac
            ip   = var.master.ip
          },
          {
            name = "worker"
            mac  = var.worker.mac
            ip   = var.worker.ip
          },
          {
            name = "infra"
            mac  = var.infra.mac
            ip   = var.infra.ip
          }
        ]
      }
    }
  ]

  # DNS según schema 0.9.1
  dns = {
    host = [
      {
        ip = var.infra.ip
        hostnames = [
          { hostname = "infra" }
        ]
      }
    ]

    # Forwarder externo (tu variable)
    forwarders = [
      { addr = var.infra_ip }
    ]
  }
}
