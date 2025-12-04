# terraform\vm-infra.tf
resource "libvirt_volume" "infra_disk" {
  name   = "okd-infra.qcow2"
  source = var.almalinux_image
  pool   = libvirt_pool.okd_pool.name
}

data "template_file" "infra_cloud_init" {
  template = file("${path.module}/files/cloud-init-infra.tpl")
  vars = {
    hostname = var.infra.hostname
    ip       = var.infra.ip
    ssh_keys = jsonencode(var.ssh_keys)
  }
}

resource "libvirt_cloudinit_disk" "infra_init" {
  name      = "infra_cloudinit.iso"
  pool      = libvirt_pool.okd_pool.name
  user_data = data.template_file.infra_cloud_init.rendered
}

resource "libvirt_domain" "infra" {
  name   = "okd-infra"
  memory = var.infra.memory
  vcpu   = var.infra.cpus

  network_interface {
    network_id = libvirt_network.okd_net.id
    addresses  = [var.infra.ip]
  }

  disk {
    volume_id = libvirt_volume.infra_disk.id
  }

  cloudinit = libvirt_cloudinit_disk.infra_init.id

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }
}
