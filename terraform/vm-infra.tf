# terraform/vm-infra.tf

# ================================
#  DISCO DEL NODO INFRA (AlmaLinux)
# ================================
resource "libvirt_volume" "infra_disk" {
  name   = "okd-infra.qcow2"
  pool   = libvirt_pool.okd.name

  target = {
    format = "qcow2"
  }

  create = {
    content = {
      # Puede ser ruta local tipo "/var/lib/libvirt/images/AlmaLinux-9.qcow2"
      url = var.almalinux_image
    }
  }
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
  name      = "infra-cloudinit.iso"
  user_data = data.template_file.infra_cloud_init.rendered

  meta_data = yamlencode({
    instance-id    = "okd-infra"
    local-hostname = var.infra.hostname
  })
}

# Volumen desde el ISO generado por cloud-init
resource "libvirt_volume" "infra_cloudinit" {
  name   = "infra-cloudinit-volume.iso"
  pool   = libvirt_pool.okd.name

  target = {
    format = "raw"
  }

  create = {
    content = {
      url = libvirt_cloudinit_disk.infra_init.path
    }
  }
}

# ================================
#  DEFINICIÓN DE LA VM INFRA
# ================================
resource "libvirt_domain" "infra" {
  name   = "okd-infra"
  vcpu   = var.infra.cpus
  memory = var.infra.memory
  type   = "kvm"

  os = {
    type = "hvm"
    arch = "x86_64"
  }

  cpu = {
    mode = "host-passthrough"
  }

  disk = [
    {
      volume_id = libvirt_volume.infra_disk.id
    },
    {
      volume_id = libvirt_volume.infra_cloudinit.id
    }
  ]

  network_interface = [{
    network_id = libvirt_network.okd_net.id
    mac        = var.infra.mac
    model      = "virtio"
  }]

  graphics = [{
    type   = "vnc"
    listen = "0.0.0.0"
  }]

  autostart = true
}
