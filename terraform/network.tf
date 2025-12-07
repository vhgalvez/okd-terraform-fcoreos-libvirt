# terraform/network.tf
resource "libvirt_network" "okd_net" {
  name    = var.network_name
  bridge  = "virbr_okd"  # Usamos solo el nombre del bridge (sin bloques)
  domain  = "${var.cluster_name}.${var.cluster_domain}"

  # No se utiliza "mode" directamente en 0.9.1
  # Red con un rango de direcciones
  addresses = [var.network_cidr]

  autostart = true

  # Configuración DHCP simplificada
  dhcp {
    enabled = true

    host {
      mac  = var.bootstrap.mac
      name = "bootstrap"
      ip   = var.bootstrap.ip
    }

    host {
      mac  = var.master.mac
      name = "master"
      ip   = var.master.ip
    }

    host {
      mac  = var.worker.mac
      name = "worker"
      ip   = var.worker.ip
    }

    host {
      mac  = var.infra.mac
      name = "infra"
      ip   = var.infra.ip
    }
  }

  # Configuración de DNS
  dns {
    enabled    = true
    local_only = false
    forwarders {
      address = var.infra_ip
    }
  }
}
