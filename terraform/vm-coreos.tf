# terraform/vm-coreos.tf
###############################################
# FEDORA COREOS BASE + DISKS (OKD NODES)
###############################################

# Volumen base de Fedora CoreOS
resource "libvirt_volume" "coreos_base" {
  name   = "fcos-base.qcow2"
  pool   = libvirt_pool.okd.name
  source = var.coreos_image
  format = "qcow2"
}

# Discos COW para los nodos
resource "libvirt_volume" "bootstrap_disk" {
  name           = "bootstrap.qcow2"
  pool           = libvirt_pool.okd.name
  base_volume_id = libvirt_volume.coreos_base.id
  format         = "qcow2"
}

resource "libvirt_volume" "master_disk" {
  name           = "master.qcow2"
  pool           = libvirt_pool.okd.name
  base_volume_id = libvirt_volume.coreos_base.id
  format         = "qcow2"
}

resource "libvirt_volume" "worker_disk" {
  name           = "worker.qcow2"
  pool           = libvirt_pool.okd.name
  base_volume_id = libvirt_volume.coreos_base.id
  format         = "qcow2"
}

###############################################
# IGNITION (libvirt_ignition) PARA NODOS FCOS
###############################################

resource "libvirt_ignition" "bootstrap" {
  name    = "bootstrap.ign"
  pool    = libvirt_pool.okd.name
  content = file("${path.module}/../generated/ignition/bootstrap.ign")
}

resource "libvirt_ignition" "master" {
  name    = "master.ign"
  pool    = libvirt_pool.okd.name
  content = file("${path.module}/../generated/ignition/master.ign")
}

resource "libvirt_ignition" "worker" {
  name    = "worker.ign"
  pool    = libvirt_pool.okd.name
  content = file("${path.module}/../generated/ignition/worker.ign")
}

###############################################
# BOOTSTRAP NODE
###############################################
resource "libvirt_domain" "bootstrap" {
  name      = "okd-bootstrap"
  vcpu      = var.bootstrap.cpus
  memory    = var.bootstrap.memory
  autostart = true

  # Disco raíz
  disk {
    volume_id = libvirt_volume.bootstrap_disk.id
  }

  # Ignition FCOS
  coreos_ignition = libvirt_ignition.bootstrap.id
  fw_cfg_name     = "opt/com.coreos/config"

  # Red
  network_interface {
    network_name   = libvirt_network.okd_net.name
    mac            = var.bootstrap.mac
    wait_for_lease = true
  }

  # Consola
  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  # VNC (compatible siempre)
  graphics {
    type           = "vnc"
    listen_type    = "address"
    listen_address = "127.0.0.1"
    autoport       = true
  }

  video {
    type = "vga"
  }
}

###############################################
# MASTER NODE
###############################################
resource "libvirt_domain" "master" {
  name      = "okd-master"
  vcpu      = var.master.cpus
  memory    = var.master.memory
  autostart = true

  disk {
    volume_id = libvirt_volume.master_disk.id
  }

  coreos_ignition = libvirt_ignition.master.id
  fw_cfg_name     = "opt/com.coreos/config"

  network_interface {
    network_name   = libvirt_network.okd_net.name
    mac            = var.master.mac
    wait_for_lease = true
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type           = "vnc"
    listen_type    = "address"
    listen_address = "127.0.0.1"
    autoport       = true
  }

  video {
    type = "vga"
  }
}


###############################################
# WORKER NODE
###############################################
resource "libvirt_domain" "worker" {
  name      = "okd-worker"
  vcpu      = var.worker.cpus
  memory    = var.worker.memory
  autostart = true

  disk {
    volume_id = libvirt_volume.worker_disk.id
  }

  coreos_ignition = libvirt_ignition.worker.id
  fw_cfg_name     = "opt/com.coreos/config"

  network_interface {
    network_name   = libvirt_network.okd_net.name
    mac            = var.worker.mac
    wait_for_lease = true
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type           = "vnc"
    listen_type    = "address"
    listen_address = "127.0.0.1"
    autoport       = true
  }

  video {
    type = "vga"
  }
}
