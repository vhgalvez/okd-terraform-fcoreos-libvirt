# Pool dedicado para OKD
resource "libvirt_pool" "okd" {
  name = "okd-pool"
  type = "dir"

  target {
    path = var.pool_path
  }
}

# ---------------------------
# Imagen base Fedora CoreOS
# ---------------------------

resource "libvirt_volume" "fcos_base" {
  name   = "fcos-base.qcow2"
  pool   = libvirt_pool.okd.name
  source = var.coreos_image
  format = "qcow2"
}

# Volúmenes para bootstrap / master / worker (con backing_store)
resource "libvirt_volume" "bootstrap_disk" {
  name           = "okd-bootstrap.qcow2"
  pool           = libvirt_pool.okd.name
  base_volume_id = libvirt_volume.fcos_base.id
  size           = var.bootstrap.disk_gb * 1024 * 1024 * 1024
}

resource "libvirt_volume" "master_disk" {
  name           = "okd-master1.qcow2"
  pool           = libvirt_pool.okd.name
  base_volume_id = libvirt_volume.fcos_base.id
  size           = var.master.disk_gb * 1024 * 1024 * 1024
}

resource "libvirt_volume" "worker_disk" {
  name           = "okd-worker1.qcow2"
  pool           = libvirt_pool.okd.name
  base_volume_id = libvirt_volume.fcos_base.id
  size           = var.worker.disk_gb * 1024 * 1024 * 1024
}

# ---------------------------
# Volumen / dominio infra (AlmaLinux con cloud-init)
# ---------------------------

resource "libvirt_volume" "infra_disk" {
  name   = "okd-infra.qcow2"
  pool   = libvirt_pool.okd.name
  source = var.infra_image
  format = "qcow2"
}

# Cloud-init para infra node (DNS+NTP básicos)
resource "libvirt_cloudinit_disk" "infra_cloudinit" {
  name = "okd-infra-cloudinit.iso"
  pool = libvirt_pool.okd.name

  user_data = templatefile("${path.module}/files/cloud-init.tpl", {
    hostname       = var.infra.name
    ip_address     = var.infra.address
    gateway        = var.gateway
    dns1           = var.dns1
    dns2           = var.dns2
    ssh_public_key = var.ssh_public_key
  })
}

resource "libvirt_domain" "infra" {
  name   = var.infra.name
  memory = var.infra.memory
  vcpu   = var.infra.vcpu

  network_interface {
    network_name = libvirt_network.okd.name
    mac          = var.infra.mac
  }

  disk {
    volume_id = libvirt_volume.infra_disk.id
  }

  cloudinit = libvirt_cloudinit_disk.infra_cloudinit.id

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type = "spice"
  }
}

# ---------------------------
# Dominios FCOS (bootstrap / master / worker)
# Ignition se conecta vía coreos_ignition (ver ignition.tf)
# ---------------------------

resource "libvirt_domain" "bootstrap" {
  name   = var.bootstrap.name
  memory = var.bootstrap.memory
  vcpu   = var.bootstrap.vcpu

  network_interface {
    network_name = libvirt_network.okd.name
    mac          = var.bootstrap.mac
  }

  disk {
    volume_id = libvirt_volume.bootstrap_disk.id
  }

  coreos_ignition = libvirt_ignition.bootstrap.id

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type = "spice"
  }
}

resource "libvirt_domain" "master" {
  name   = var.master.name
  memory = var.master.memory
  vcpu   = var.master.vcpu

  network_interface {
    network_name = libvirt_network.okd.name
    mac          = var.master.mac
  }

  disk {
    volume_id = libvirt_volume.master_disk.id
  }

  coreos_ignition = libvirt_ignition.master.id

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type = "spice"
  }
}

resource "libvirt_domain" "worker" {
  name   = var.worker.name
  memory = var.worker.memory
  vcpu   = var.worker.vcpu

  network_interface {
    network_name = libvirt_network.okd.name
    mac          = var.worker.mac
  }

  disk {
    volume_id = libvirt_volume.worker_disk.id
  }

  coreos_ignition = libvirt_ignition.worker.id

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type = "spice"
  }
}
