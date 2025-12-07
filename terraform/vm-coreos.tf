# terraform/vm-coreos.tf

###############################################
# BASE IMAGE FOR FEDORA COREOS
###############################################
resource "libvirt_volume" "coreos_base" {
  name = "fcos-base.qcow2"
  pool = libvirt_pool.okd.name

  create = {
    content = {
      url = var.coreos_image
    }
  }
}

###############################################
# VM DISKS (Copy-on-write overlays)
###############################################
resource "libvirt_volume" "bootstrap_disk" {
  name = "bootstrap.qcow2"
  pool = libvirt_pool.okd.name

  backing_store = {
    path   = libvirt_volume.coreos_base.path
    format = "qcow2"
  }
}

resource "libvirt_volume" "master_disk" {
  name = "master.qcow2"
  pool = libvirt_pool.okd.name

  backing_store = {
    path   = libvirt_volume.coreos_base.path
    format = "qcow2"
  }
}

resource "libvirt_volume" "worker_disk" {
  name = "worker.qcow2"
  pool = libvirt_pool.okd.name

  backing_store = {
    path   = libvirt_volume.coreos_base.path
    format = "qcow2"
  }
}

###############################################
# IGNITION DISKS
###############################################
resource "libvirt_volume" "bootstrap_ignition" {
  name   = "bootstrap.ign"
  pool   = libvirt_pool.okd.name
  format = "raw"

  create = {
    content = {
      url = libvirt_ignition.bootstrap.path
    }
  }
}

resource "libvirt_volume" "master_ignition" {
  name   = "master.ign"
  pool   = libvirt_pool.okd.name
  format = "raw"

  create = {
    content = {
      url = libvirt_ignition.master.path
    }
  }
}

resource "libvirt_volume" "worker_ignition" {
  name   = "worker.ign"
  pool   = libvirt_pool.okd.name
  format = "raw"

  create = {
    content = {
      url = libvirt_ignition.worker.path
    }
  }
}

###############################################
# BOOTSTRAP NODE
###############################################
resource "libvirt_domain" "bootstrap" {
  name    = "okd-bootstrap"
  vcpu    = var.bootstrap.cpus
  memory  = var.bootstrap.memory
  type    = "kvm"

  # ✅ CORRECCIÓN: 'os', 'disk', 'network_interface', 'graphics' se definen como argumentos de lista de mapas.
  os = {
    type    = "hvm"
    arch    = "x86_64"
    machine = "q35"
  }

  disk = [
    { volume_id = libvirt_volume.bootstrap_disk.id },
    { volume_id = libvirt_volume.bootstrap_ignition.id }
  ]

  network_interface = [{
    network_id = libvirt_network.okd_net.id
    mac        = var.bootstrap.mac
    model      = "virtio"
  }]

  graphics = [{
    type   = "vnc"
    listen = "0.0.0.0"
  }]

  autostart = true
}

###############################################
# MASTER NODE
###############################################
resource "libvirt_domain" "master" {
  name    = "okd-master"
  vcpu    = var.master.cpus
  memory  = var.master.memory
  type    = "kvm"

  # ✅ CORRECCIÓN: Argumentos de lista de mapas.
  os = {
    type    = "hvm"
    arch    = "x86_64"
    machine = "q35"
  }

  disk = [
    { volume_id = libvirt_volume.master_disk.id },
    { volume_id = libvirt_volume.master_ignition.id }
  ]

  network_interface = [{
    network_id = libvirt_network.okd_net.id
    mac        = var.master.mac
    model      = "virtio"
  }]

  graphics = [{
    type   = "vnc"
    listen = "0.0.0.0"
  }]

  autostart = true
}

###############################################
# WORKER NODE
###############################################
resource "libvirt_domain" "worker" {
  name    = "okd-worker"
  vcpu    = var.worker.cpus
  memory  = var.worker.memory
  type    = "kvm"

  # ✅ CORRECCIÓN: Argumentos de lista de mapas.
  os = {
    type    = "hvm"
    arch    = "x86_64"
    machine = "q35"
  }

  disk = [
    { volume_id = libvirt_volume.worker_disk.id },
    { volume_id = libvirt_volume.worker_ignition.id }
  ]

  network_interface = [{
    network_id = libvirt_network.okd_net.id
    mac        = var.worker.mac
    model      = "virtio"
  }]

  graphics = [{
    type   = "vnc"
    listen = "0.0.0.0"
  }]

  autostart = true
}