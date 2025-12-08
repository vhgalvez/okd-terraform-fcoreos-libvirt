# terraform/network.tf

###############################################
# RED OKD (libvirt_network)
###############################################
resource "libvirt_network" "okd_net" {
  name      = var.network_name
  autostart = true

  bridge = {
    name = "virbr_okd"
  }

  domain = {
    name = "${var.cluster_name}.${var.cluster_domain}"
  }

  ips = [
    {
      family  = "ipv4"
      address = cidrhost(var.network_cidr, 1) # 10.56.0.1
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
      { addr = var.infra_ip }
    ]
  }
}
