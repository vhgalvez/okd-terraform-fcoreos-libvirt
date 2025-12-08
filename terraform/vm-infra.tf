# terraform/vm-infra.tf
###############################################
# DISCO DEL NODO INFRA (AlmaLinux)
###############################################
resource "libvirt_volume" "infra_disk" {
  name = "okd-infra.qcow2"
  pool = libvirt_pool.okd.name

  # Importa la imagen local de AlmaLinux (qcow2)
  create = {
    content = {
      url = var.almalinux_image
    }
  }

  target = {
    format = {
      type = "qcow2"
    }
  }
}

###############################################
# CLOUD-INIT TEMPLATE (AlmaLinux)
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
# CLOUD-INIT DISK (libvirt_cloudinit_disk)
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
# CLOUD-INIT RAW VOLUME
###############################################
resource "libvirt_volume" "infra_cloudinit" {
  name = "infra-cloudinit.raw"
  pool = libvirt_pool.okd.name

  create = {
    content = {
      url = libvirt_cloudinit_disk.infra_init.path
    }
  }

  target = {
    format = {
      type = "raw"
    }
  }
}

###############################################
# VM INFRA (DNS + NTP + HAProxy + CoreDNS)
###############################################
resource "libvirt_domain" "infra" {
  name      = "okd-infra"
  type      = "kvm"
  vcpu      = var.infra.cpus
  memory    = var.infra.memory
  autostart = true

  os  = local.domain_os
  cpu = local.cpu_conf

  devices = {

    ###########################################
    # DISKS
    ###########################################
    disks = [
      {
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
        source = {
          volume = {
            pool   = libvirt_volume.infra_cloudinit.pool
            volume = libvirt_volume.infra_cloudinit.name
          }
        }
        target = {
          dev = "vdb"
          bus = "virtio"
        }
      }
    ]

    ###########################################
    # NETWORK INTERFACE
    ###########################################
    interfaces = [
      {
        model = { type = "virtio" }
        source = {
          network = { network = libvirt_network.okd_net.name }
        }
        mac = { address = var.infra.mac }
      }
    ]

    ###########################################
    # CONSOLE
    ###########################################
    consoles = [
      {
        type        = "pty"
        target_type = "serial"
        target_port = "0"
      }
    ]

    ###########################################
    # GRAPHICS — VNC (SINTAXIS REAL 0.9.1)
    ###########################################
    graphics = [
      {
        type     = "vnc"
        listen   = "127.0.0.1"
        autoport = "yes"
      }
    ]

    ###########################################
    # VIDEO — VGA (COMPATIBLE)
    ###########################################
    videos = [
      {
        model = {
          type = "vga"
        }
      }
    ]
  }

  running = true
}
