# terraform/vm-coreos.tf

###############################################
# BASE IMAGE FOR FEDORA COREOS
###############################################
resource "libvirt_volume" "coreos_base" {
  name   = "fcos-base.qcow2"
  pool   = libvirt_pool.okd.name
  source = var.coreos_image
}

###############################################
# VM DISKS
###############################################
resource "libvirt_volume" "bootstrap_disk" {
  name           = "bootstrap.qcow2"
  pool           = libvirt_pool.okd.name
  base_volume_id = libvirt_volume.coreos_base.id
}

resource "libvirt_volume" "master_disk" {
  name           = "master.qcow2"
  pool           = libvirt_pool.okd.name
  base_volume_id = libvirt_volume.coreos_base.id
}

resource "libvirt_volume" "worker_disk" {
  name           = "worker.qcow2"
  pool           = libvirt_pool.okd.name
  base_volume_id = libvirt_volume.coreos_base.id
}

###############################################################
# BOOTSTRAP NODE
###############################################################
resource "libvirt_domain" "bootstrap" {
  name      = "okd-bootstrap"
  memory    = var.bootstrap.memory
  vcpu      = var.bootstrap.cpus
  autostart = true

  cpu {
    mode = "host-passthrough"
  }

  network_interface {
    network_name = libvirt_network.okd_net.name
    mac          = var.bootstrap.mac
  }

  disk {
    volume_id = libvirt_volume.bootstrap_disk.id
  }

  coreos_ignition = libvirt_ignition.bootstrap.id

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

###############################################################
# MASTER NODE
###############################################################
resource "libvirt_domain" "master" {
  name      = "okd-master"
  memory    = var.master.memory
  vcpu      = var.master.cpus
  autostart = true

  cpu {
    mode = "host-passthrough"
  }

  network_interface {
    network_name = libvirt_network.okd_net.name
    mac          = var.master.mac
  }

  disk {
    volume_id = libvirt_volume.master_disk.id
  }

  coreos_ignition = libvirt_ignition.master.id

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

###############################################################
# WORKER NODE
###############################################################
resource "libvirt_domain" "worker" {
  name      = "okd-worker"
  memory    = var.worker.memory
  vcpu      = var.worker.cpus
  autostart = true

  cpu {
    mode = "host-passthrough"
  }

  network_interface {
    network_name = libvirt_network.okd_net.name
    mac          = var.worker.mac
  }

  disk {
    volume_id = libvirt_volume.worker_disk.id
  }

  coreos_ignition = libvirt_ignition.worker.id

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
