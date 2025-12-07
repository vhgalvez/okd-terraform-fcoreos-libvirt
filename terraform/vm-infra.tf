# terraform/vm-infra.tf
###############################################
# DISCO DEL NODO INFRA (AlmaLinux)
###############################################
resource "libvirt_volume" "infra_disk_infra" {
  name = "okd-infra.qcow2"
  pool = libvirt_pool.okd.name

  # Imagen base AlmaLinux (ruta local o URL)
  # OJO: var.almalinux_image debe existir y ser legible por libvirtd
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

  lifecycle {
    ignore_exists = true
  }
}

###############################################
# CLOUD-INIT TEMPLATE
###############################################
data "template_file" "infra_cloud_init_infra" {
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
# CLOUD-INIT ISO
###############################################
resource "libvirt_cloudinit_disk" "infra_init_infra" {
  name      = "infra-cloudinit"
  user_data = data.template_file.infra_cloud_init_infra.rendered

  meta_data = yamlencode({
    instance-id    = "okd-infra"
    local-hostname = var.infra.hostname
  })
}

resource "libvirt_volume" "infra_cloudinit_infra" {
  name = "infra-cloudinit.iso"
  pool = libvirt_pool.okd.name

  create = {
    content = {
      url = libvirt_cloudinit_disk.infra_init_infra.path
    }
  }

  target = {
    format = {
      type = "raw"
    }
  }

  lifecycle {
    ignore_exists = true
  }
}

###############################################
# VM INFRA (HAProxy + CoreDNS)
###############################################
resource "libvirt_domain" "infra_infra" {
  name      = "okd-infra"
  type      = "kvm"
  vcpu      = var.infra.cpus
  memory    = var.infra.memory
  autostart = true

  cpu = {
    mode = "host-passthrough"
  }

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
    boot_devices = [{ dev = "hd" }]
  }

  devices = {
    disks = [
      {
        # Disco principal de AlmaLinux
        source = {
          volume = {
            pool   = libvirt_volume.infra_disk_infra.pool
            volume = libvirt_volume.infra_disk_infra.name
          }
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
      },
      {
        # Segundo disco: ISO de cloud-init
        source = {
          volume = {
            pool   = libvirt_volume.infra_cloudinit_infra.pool
            volume = libvirt_volume.infra_cloudinit_infra.name
          }
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
        mac = { address = var.infra.mac }
      }
    ]
  }
}
