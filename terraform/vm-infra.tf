# terraform/vm-infra.tf

###############################################
# DISCO DEL NODO INFRA (AlmaLinux)
###############################################
resource "libvirt_volume" "infra_disk" {
  name   = "okd-infra.qcow2"
  pool   = libvirt_pool.okd.name
  format = "qcow2"

  create = {
    content = {
      url = var.almalinux_image
    }
  }
}

###############################################
# CLOUD-INIT (GENERACIÓN ISO)
# - NO tiene pool/pool_name según tu schema
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

    ssh_keys = join("\n", var.ssh_keys)
    timezone = var.timezone
  }
}

resource "libvirt_cloudinit_disk" "infra_init" {
  name      = "infra-init"
  user_data = data.template_file.infra_cloud_init.rendered

  meta_data = yamlencode({
    instance-id    = "okd-infra"
    local-hostname = var.infra.hostname
  })
}

###############################################
# SUBIR EL ISO DE CLOUD-INIT AL POOL
###############################################
resource "libvirt_volume" "infra_cloudinit" {
  name   = "infra-cloudinit.iso"
  pool   = libvirt_pool.okd.name
  format = "raw"

  create = {
    content = {
      url = libvirt_cloudinit_disk.infra_init.path
    }
  }
}

###############################################
# VM INFRA (0.9.1 - patrón devices)
###############################################
resource "libvirt_domain" "infra" {
  name      = "okd-infra"
  type      = "kvm"
  vcpu      = var.infra.cpus
  memory    = var.infra.memory
  autostart = true

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
    boot_devices = ["hd"]
  }

  cpu = {
    mode = "host-passthrough"
  }

  devices = {
    disks = [
      {
        source = {
          pool   = libvirt_volume.infra_disk.pool
          volume = libvirt_volume.infra_disk.name
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
      },
      {
        source = {
          pool   = libvirt_volume.infra_cloudinit.pool
          volume = libvirt_volume.infra_cloudinit.name
        }
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
          network = {
            network = libvirt_network.okd_net.name
          }
        }
        mac = var.infra.mac
      }
    ]

    graphics = {
      vnc = {
        listen   = "0.0.0.0"
        autoport = true
      }
    }
  }
}
