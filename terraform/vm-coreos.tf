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

  # CPU Configuration (should be an object, not a string)
  cpu {
    mode = "host-passthrough"
  }

  # Network interface
  network_interface {
    network_id = libvirt_network.okd_net.id
    mac        = var.bootstrap.mac
  }

  # Disk Configuration
  disk {
    volume_id = libvirt_volume.bootstrap_disk.id
  }

  # Ignition
  ignition = libvirt_ignition.bootstrap.id

  # Gráficos
  graphics = {
    type    = "vnc"
    listen  = "0.0.0.0"
    autoport = true
  }

  # Video Configuration
  video = {
    type = "vga"
  }

  # Consola
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

  # CPU Configuration (should be an object, not a string)
  cpu {
    mode = "host-passthrough"
  }

  # Network interface
  network_interface {
    network_id = libvirt_network.okd_net.id
    mac        = var.master.mac
  }

  # Disk Configuration
  disk {
    volume_id = libvirt_volume.master_disk.id
  }

  # Ignition
  ignition = libvirt_ignition.master.id

  # Gráficos
  graphics = {
    type    = "vnc"
    listen  = "0.0.0.0"
    autoport = true
  }

  # Video Configuration
  video = {
    type = "vga"
  }

  # Consola
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

  # CPU Configuration (should be an object, not a string)
  cpu {
    mode = "host-passthrough"
  }

  # Network interface
  network_interface {
    network_id = libvirt_network.okd_net.id
    mac        = var.worker.mac
  }

  # Disk Configuration
  disk {
    volume_id = libvirt_volume.worker_disk.id
  }

  # Ignition
  ignition = libvirt_ignition.worker.id

  # Gráficos
  graphics = {
    type    = "vnc"
    listen  = "0.0.0.0"
    autoport = true
  }

  # Video Configuration
  video = {
    type = "vga"
  }

  # Consola
  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }
}
