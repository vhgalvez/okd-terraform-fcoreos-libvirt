# terraform\vm-coreos.tf
###############################################
# FEDORA COREOS BASE
###############################################
resource "libvirt_volume" "coreos_base" {
  name   = "fcos-base.qcow2"
  pool   = libvirt_pool.okd.name
  source = var.coreos_image
  format = "qcow2"
}

###############################################
# OVERLAY DISKS (Bootstrap + 3 Masters + Worker)
###############################################

resource "libvirt_volume" "bootstrap_disk" {
  name           = "bootstrap.qcow2"
  pool           = libvirt_pool.okd.name
  base_volume_id = libvirt_volume.coreos_base.id
  format         = "qcow2"
}

resource "libvirt_volume" "master1_disk" {
  name           = "master1.qcow2"
  pool           = libvirt_pool.okd.name
  base_volume_id = libvirt_volume.coreos_base.id
  format         = "qcow2"
}

resource "libvirt_volume" "master2_disk" {
  name           = "master2.qcow2"
  pool           = libvirt_pool.okd.name
  base_volume_id = libvirt_volume.coreos_base.id
  format         = "qcow2"
}

resource "libvirt_volume" "master3_disk" {
  name           = "master3.qcow2"
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
# IGNITION FILES
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

  disk { volume_id = libvirt_volume.bootstrap_disk.id }

  network_interface {
    network_name   = libvirt_network.okd_net.name
    mac            = var.bootstrap.mac
    addresses      = [var.bootstrap.ip]
    hostname       = var.bootstrap.hostname
    wait_for_lease = true
  }

  cpu { mode = "host-passthrough" }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = 0
  }

  graphics {
    type           = "vnc"
    listen_type    = "address"
    listen_address = "127.0.0.1"
    autoport       = true
  }

  video { type = "vga" }

  coreos_ignition = libvirt_ignition.bootstrap.id
  fw_cfg_name     = "opt/com.coreos/config"
}

###############################################
# MASTER 1
###############################################

resource "libvirt_domain" "master1" {
  name      = "okd-master1"
  vcpu      = var.master1.cpus
  memory    = var.master1.memory
  autostart = true

  disk { volume_id = libvirt_volume.master1_disk.id }

  cpu { mode = "host-passthrough" }

  network_interface {
    network_name   = libvirt_network.okd_net.name
    mac            = var.master1.mac
    addresses      = [var.master1.ip]
    hostname       = var.master1.hostname
    wait_for_lease = true
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = 0
  }

  graphics {
    type           = "vnc"
    listen_type    = "address"
    listen_address = "127.0.0.1"
    autoport       = true
  }

  video { type = "vga" }

  coreos_ignition = libvirt_ignition.master.id
  fw_cfg_name     = "opt/com.coreos/config"
}

###############################################
# MASTER 2
###############################################

resource "libvirt_domain" "master2" {
  name      = "okd-master2"
  vcpu      = var.master2.cpus
  memory    = var.master2.memory
  autostart = true

  disk { volume_id = libvirt_volume.master2_disk.id }

  cpu { mode = "host-passthrough" }

  network_interface {
    network_name   = libvirt_network.okd_net.name
    mac            = var.master2.mac
    addresses      = [var.master2.ip]
    hostname       = var.master2.hostname
    wait_for_lease = true
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = 0
  }

  graphics {
    type           = "vnc"
    listen_type    = "address"
    listen_address = "127.0.0.1"
    autoport       = true
  }

  video { type = "vga" }

  coreos_ignition = libvirt_ignition.master.id
  fw_cfg_name     = "opt/com.coreos/config"
}

###############################################
# MASTER 3
###############################################

resource "libvirt_domain" "master3" {
  name      = "okd-master3"
  vcpu      = var.master3.cpus
  memory    = var.master3.memory
  autostart = true

  disk { volume_id = libvirt_volume.master3_disk.id }

  cpu { mode = "host-passthrough" }

  network_interface {
    network_name   = libvirt_network.okd_net.name
    mac            = var.master3.mac
    addresses      = [var.master3.ip]
    hostname       = var.master3.hostname
    wait_for_lease = true
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = 0
  }

  graphics {
    type           = "vnc"
    listen_type    = "address"
    listen_address = "127.0.0.1"
    autoport       = true
  }

  video { type = "vga" }

  coreos_ignition = libvirt_ignition.master.id
  fw_cfg_name     = "opt/com.coreos/config"
}

###############################################
# WORKER NODE
###############################################

resource "libvirt_domain" "worker" {
  name      = "okd-worker"
  vcpu      = var.worker.cpus
  memory    = var.worker.memory
  autostart = true

  disk { volume_id = libvirt_volume.worker_disk.id }

  cpu { mode = "host-passthrough" }

  network_interface {
    network_name   = libvirt_network.okd_net.name
    mac            = var.worker.mac
    addresses      = [var.worker.ip]
    hostname       = var.worker.hostname
    wait_for_lease = true
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = 0
  }

  graphics {
    type           = "vnc"
    listen_type    = "address"
    listen_address = "127.0.0.1"
    autoport       = true
  }

  video { type = "vga" }

  coreos_ignition = libvirt_ignition.worker.id
  fw_cfg_name     = "opt/com.coreos/config"
}
