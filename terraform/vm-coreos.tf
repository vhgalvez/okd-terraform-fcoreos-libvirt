# terraform/vm-coreos.tf

#############################################
# BASE COREOS IMAGE
#############################################

resource "libvirt_volume" "coreos_base" {
  name   = "fcos-base"
  source = var.coreos_image
  pool   = libvirt_pool.okd.name
}

resource "libvirt_volume" "bootstrap_disk" {
  name           = "bootstrap.qcow2"
  base_volume_id = libvirt_volume.coreos_base.id
  pool           = libvirt_pool.okd.name
}

resource "libvirt_volume" "master_disk" {
  name           = "master.qcow2"
  base_volume_id = libvirt_volume.coreos_base.id
  pool           = libvirt_pool.okd.name
}

resource "libvirt_volume" "worker_disk" {
  name           = "worker.qcow2"
  base_volume_id = libvirt_volume.coreos_base.id
  pool           = libvirt_pool.okd.name
}

#############################################
# BOOTSTRAP NODE
#############################################

resource "libvirt_domain" "bootstrap" {
  name      = "okd-bootstrap"
  memory    = var.bootstrap.memory
  vcpu      = var.bootstrap.cpus
  addresses  = [var.bootstrap.ip]
  autostart = true

  cpu {
    mode = "host-passthrough"
  }

  network_interface {
    network_id = libvirt_network.okd_net.id
    mac        = var.bootstrap.mac
    # No uses "addresses": Ignition configura la IP real.
  }

  disk {
    volume_id = libvirt_volume.bootstrap_disk.id
  }

  # Ignition de OpenShift
  coreos_ignition = libvirt_ignition.bootstrap.id

  # VNC obligatorio (SPICE no soportado en tu QEMU)
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

#############################################
# MASTER NODE
#############################################

resource "libvirt_domain" "master" {
  name      = "okd-master"
  memory    = var.master.memory
  vcpu      = var.master.cpus
  addresses  = [var.master.ip]
  autostart = true

  cpu {
    mode = "host-passthrough"
  }

  network_interface {
    network_id = libvirt_network.okd_net.id
    mac        = var.master.mac
  }

  disk {
    volume_id = libvirt_volume.master_disk.id
  }

  coreos_ignition = libvirt_ignition.master.id

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

#############################################
# WORKER NODE
#############################################

resource "libvirt_domain" "worker" {
  name      = "okd-worker"
  memory    = var.worker.memory
  vcpu      = var.worker.cpus
  addresses  = [var.worker.ip]
  autostart = true

  cpu {
    mode = "host-passthrough"
  }

  network_interface {
    network_id = libvirt_network.okd_net.id
    mac        = var.worker.mac
  }

  disk {
    volume_id = libvirt_volume.worker_disk.id
  }

  coreos_ignition = libvirt_ignition.worker.id

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