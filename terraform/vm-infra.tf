# terraform/vm-infra.tf

# ================================
#  DISCO DEL NODO INFRA
# ================================
resource "libvirt_volume" "infra_disk" {
  name   = "okd-infra.qcow2"
  source = var.almalinux_image
  pool   = libvirt_pool.okd.name
}

# ================================
#  CLOUD-INIT DEL NODO INFRA
# ================================
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

resource "libvirt_cloudinit_disk" "infra_init" {
  name      = "infra_cloudinit.iso"
  pool      = libvirt_pool.okd.name
  user_data = data.template_file.infra_cloud_init.rendered
}

# ================================
#  DEFINICIÓN DE LA VM INFRA
# ================================
resource "libvirt_domain" "infra" {
  name   = "okd-infra"
  memory = var.infra.memory
  vcpu   = var.infra.cpus

  cpu {
    mode = "host-passthrough"
  }

  network_interface {
    network_name = libvirt_network.okd_net.name
    mac          = var.infra.mac
  }

  disk {
    volume_id = libvirt_volume.infra_disk.id
  }

  cloudinit_disk = libvirt_cloudinit_disk.infra_init.id

  graphics = {
    type   = "vnc"
    listen = "0.0.0.0"
  }

  video {
    type = "vga"
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }
}
