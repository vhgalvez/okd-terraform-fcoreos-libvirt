# terraform/vm-infra.tf

resource "libvirt_volume" "infra_disk" {
  name = "okd-infra.qcow2"
  pool = libvirt_pool.okd.name

  create = {
    content = {
      url = var.almalinux_image
    }
  }
}

data "template_file" "infra_cloud_init" {
  template = file("${path.module}/files/cloud-init-infra.tpl")

  vars = {
    hostname       = var.infra.hostname
    ip             = var.infra.ip
    gateway        = var.gateway
    dns1           = var.dns1
    dns2           = var.dns2
    cluster_name   = var.cluster_name
    cluster_domain = var.cluster_domain
    ssh_keys       = join("\n          - ", var.ssh_keys)
    timezone       = var.timezone
  }
}

resource "libvirt_cloudinit_disk" "infra_init" {
  name        = "infra-cloudinit.iso"
  user_data   = data.template_file.infra_cloud_init.rendered

  meta_data = yamlencode({
    instance-id    = "okd-infra"
    local-hostname = var.infra.hostname
  })

  # ✅ CORRECCIÓN (v0.6.x/v0.10+): Se usa el argumento 'pool' (no 'pool_name').
  pool = libvirt_pool.okd.name
}

resource "libvirt_domain" "infra" {
  name   = "okd-infra"
  vcpu   = var.infra.cpus
  memory = var.infra.memory
  type   = "kvm"

  # ✅ CORRECCIÓN: 'os' es ahora un argumento (mapa).
  os = {
    type = "hvm"
    arch = "x86_64"
  }

  # ✅ CORRECCIÓN: 'disk' es ahora una lista de mapas.
  disk = [
    { volume_id = libvirt_volume.infra_disk.id },
    { volume_id = libvirt_cloudinit_disk.infra_init.id }
  ]

  # ✅ CORRECCIÓN: 'network_interface' es ahora una lista de mapas.
  network_interface = [{
    network_id = libvirt_network.okd_net.id
    mac        = var.infra.mac
    model      = "virtio"
  }]

  # ✅ CORRECCIÓN: 'graphics' es ahora una lista de mapas.
  graphics = [{
    type   = "vnc"
    listen = "0.0.0.0"
  }]

  autostart = true
}