# terraform\vm-infra.tf
###############################################
# DISCO DEL NODO INFRA (AlmaLinux)
###############################################
resource "libvirt_volume" "infra_disk" {
  name = "okd-infra.qcow2"
  pool = libvirt_pool.okd.name

  # Importa la imagen local de AlmaLinux (Sintaxis v0.9.1)
  create {
    content {
      url = var.almalinux_image
    }
  }

  target {
    format = "qcow2"
  }
}

###############################################
# CLOUD-INIT TEMPLATE
###############################################
data "template_file" "infra_cloud_init" {
  template = file("${path.module}/files/cloud-init-infra.tpl")

  vars = {
    hostname       = var.infra.hostname
    short_hostname = split(".", var.infra.hostname)[0]

    ip      = var.infra.ip
    gateway = var.gateway

    dns1 = var.dns1
    dns2 = var.dns2

    cluster_domain = var.cluster_domain
    cluster_name   = var.cluster_name
    cluster_fqdn   = "${var.cluster_name}.${var.cluster_domain}"

    ssh_keys = join("\n", var.ssh_keys)
    timezone = var.timezone
  }
}

###############################################
# CLOUD-INIT DISK
###############################################
resource "libvirt_cloudinit_disk" "infra_init" {
  name      = "infra-cloudinit"
  user_data = data.template_file.infra_cloud_init.rendered

  meta_data = yamlencode({
    "instance-id"    = "okd-infra"
    "local-hostname" = var.infra.hostname
  })
}

###############################################
# VM INFRA (HAProxy + CoreDNS)
###############################################
resource "libvirt_domain" "infra" {
  name      = "okd-infra"
  type      = "kvm"
  vcpu      = var.infra.cpus
  memory    = var.infra.memory
  autostart = true

  cpu {
    mode = "host-passthrough"
  }

  os {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
    boot_devices = [{ dev = "hd" }]
  }

  # CONFIGURACIÓN DE GRÁFICOS (VNC) - Bloque de nivel superior
  graphics {
    type     = "vnc"
    autoport = true
    listen   = "127.0.0.1" # ✅ Actualizado a acceso local (localhost)
  }

  devices {
    disks = [
      {
        # 1. Disco principal de AlmaLinux (vda)
        source = {
          volume = {
            pool   = libvirt_volume.infra_disk.pool
            volume = libvirt_volume.infra_disk.name
          }
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
      },
      {
        # 2. Disco Cloud-Init (vdb) - Sintaxis de conexión v0.9.1
        cloudinit = libvirt_cloudinit_disk.infra_init.id
        target = {
          dev = "vdb"
          bus = "virtio"
        }
      }
    ]

    interfaces = [
      {
        model = { type = "virtio" }
        source = {
          network = { network = libvirt_network.okd_net.name }
        }
        mac = { address = var.infra.mac }
      }
    ]

    consoles = [
      {
        type        = "pty"
        target_type = "serial"
        target_port = "0"
      }
    ]

    # TARJETA DE VIDEO (video como bloque dentro de devices)
    video {
      model {
        type = "qxl"
      }
    }
  }
}
