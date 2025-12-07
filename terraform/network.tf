# terraform/network.tf

resource "libvirt_network" "okd_net" {
  name   = var.network_name
  mode   = "nat"
  bridge = "virbr_okd"

  # Dominio DNS: okd.okd.local
  domain = "${var.cluster_name}.${var.cluster_domain}"

  addresses = [var.network_cidr]
  autostart = true

  #############################################
  # DHCP para nodos FCOS (Bootstrap, Master, Worker)
  #############################################
  dhcp {
    enabled = true

    # BOOTSTRAP
    host {
      mac  = var.bootstrap.mac
      name = "bootstrap"
      ip   = var.bootstrap.ip
    }

    # MASTER
    host {
      mac  = var.master.mac
      name = "master"
      ip   = var.master.ip
    }

    # WORKER
    host {
      mac  = var.worker.mac
      name = "worker"
      ip   = var.worker.ip
    }
  }

  #############################################
  # DNS FORWARDER → Va al nodo infra (IP fija via cloud-init)
  #############################################
  dns {
    enabled    = true
    local_only = false

    forwarders {
      address = var.infra_ip # 10.56.0.10
    }
  }
}
