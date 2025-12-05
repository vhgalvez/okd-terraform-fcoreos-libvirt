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
    ip             = var.infra.ip
    gateway        = var.gateway
    dns1           = var.dns1
    dns2           = var.dns2
    cluster_domain = var.cluster_domain
    ssh_keys       = jsonencode(var.ssh_keys)
    timezone       = var.timezone
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
    network_id = libvirt_network.okd_net.id
    addresses  = [var.infra.ip]
  }

  disk {
    volume_id = libvirt_volume.infra_disk.id
  }

  cloudinit = libvirt_cloudinit_disk.infra_init.id

  # 🔥 FORZAMOS VNC — evita SPICE y corrige el error:
  # “spice graphics are not supported with this QEMU”
  graphics {
    type           = "vnc"
    autoport       = true
    listen_type    = "address"
    listen_address = "0.0.0.0"
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