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

  target { # CORRECCIÓN: target como bloque singular
    format = "qcow2"
  }
}

------------------------------------------------
# VM DISKS (Copy-on-write overlays)
###############################################
resource "libvirt_volume" "bootstrap_disk" {
  name     = "bootstrap.qcow2"
  pool     = libvirt_pool.okd.name
  capacity = 107374182400

  backing_store { # CORRECCIÓN: backing_store como bloque
    path   = libvirt_volume.coreos_base.path
    format = "qcow2"
  }
  target { format = "qcow2" } # CORRECCIÓN
}

resource "libvirt_volume" "master_disk" {
  name     = "master.qcow2"
  pool     = libvirt_pool.okd.name
  capacity = 107374182400

  backing_store { # CORRECCIÓN
    path   = libvirt_volume.coreos_base.path
    format = "qcow2"
  }
  target { format = "qcow2" } # CORRECCIÓN
}

resource "libvirt_volume" "worker_disk" {
  name     = "worker.qcow2"
  pool     = libvirt_pool.okd.name
  capacity = 107374182400

  backing_store { # CORRECCIÓN
    path   = libvirt_volume.coreos_base.path
    format = "qcow2"
  }
  target { format = "qcow2" } # CORRECCIÓN
}

------------------------------------------------
# IGNITION RAW VOLUMES
###############################################
resource "libvirt_ignition" "bootstrap" {
  name    = "bootstrap.ign"
  content = file("${path.module}/../generated/ignition/bootstrap.ign")
}

resource "libvirt_ignition" "master" {
  name    = "master.ign"
  content = file("${path.module}/../generated/ignition/master.ign")
}

resource "libvirt_ignition" "worker" {
  name    = "worker.ign"
  content = file("${path.module}/../generated/ignition/worker.ign")
}

resource "libvirt_volume" "bootstrap_ignition" {
  name = "bootstrap-ignition.raw"
  pool = libvirt_pool.okd.name

  create = { content = { url = libvirt_ignition.bootstrap.path } }
  target { format = "raw" } # CORRECCIÓN
}

resource "libvirt_volume" "master_ignition" {
  name  = "master-ignition.raw"
  pool  = libvirt_pool.okd.name
  create = { content = { url = libvirt_ignition.master.path } }
  target { format = "raw" } # CORRECCIÓN
}

resource "libvirt_volume" "worker_ignition" {
  name  = "worker-ignition.raw"
  pool  = libvirt_pool.okd.name
  create = { content = { url = libvirt_ignition.worker.path } }
  target { format = "raw" } # CORRECCIÓN
}

------------------------------------------------
# LOCAL DEFINITIONS
###############################################
locals {
  domain_os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
    boot_devices = [{ dev = "hd" }]
  }

  cpu_conf = {
    mode = "host-passthrough"
  }
}

------------------------------------------------
# BOOTSTRAP NODE
###############################################
resource "libvirt_domain" "bootstrap" {
  name      = "okd-bootstrap"
  type      = "kvm"
  vcpu      = var.bootstrap.cpus
  memory    = var.bootstrap.memory
  autostart = true

  os  = local.domain_os
  cpu = local.cpu_conf

  devices { # CORRECCIÓN: devices como bloque
    disk { # disk como bloque
      source {
        volume {
          pool   = libvirt_volume.bootstrap_disk.pool
          volume = libvirt_volume.bootstrap_disk.name
        }
      }
      target { # CORRECCIÓN: target como bloque (disco de arranque vda)
        dev = "vda"
        bus = "virtio"
      }
    }
    disk {
      source {
        volume {
          pool   = libvirt_volume.bootstrap_ignition.pool
          volume = libvirt_volume.bootstrap_ignition.name
        }
      }
      target { # CORRECCIÓN (disco ignition vdb)
        dev = "vdb"
        bus = "virtio"
      }
    }

    interface { # interface como bloque
      model { type = "virtio" }
      source { network { network = libvirt_network.okd_net.name } }
      mac { address = var.bootstrap.mac }
    }

    console { # CORRECCIÓN: console como bloque singular
      type        = "pty"
      target_type = "serial"
      target_port = "0"
    }
  }
}

------------------------------------------------
# MASTER NODE
###############################################
resource "libvirt_domain" "master" {
  name      = "okd-master"
  type      = "kvm"
  vcpu      = var.master.cpus
  memory    = var.master.memory
  autostart = true

  os  = local.domain_os
  cpu = local.cpu_conf

  devices { # CORRECCIÓN
    disk {
      source {
        volume {
          pool   = libvirt_volume.master_disk.pool
          volume = libvirt_volume.master_disk.name
        }
      }
      target { # CORRECCIÓN
        dev = "vda"
        bus = "virtio"
      }
    }
    disk {
      source {
        volume {
          pool   = libvirt_volume.master_ignition.pool
          volume = libvirt_volume.master_ignition.name
        }
      }
      target { # CORRECCIÓN
        dev = "vdb"
        bus = "virtio"
      }
    }

    interface {
      model { type = "virtio" }
      source { network { network = libvirt_network.okd_net.name } }
      mac { address = var.master.mac }
    }

    console { # CORRECCIÓN
      type        = "pty"
      target_type = "serial"
      target_port = "0"
    }
  }
}

------------------------------------------------
# WORKER NODE
###############################################
resource "libvirt_domain" "worker" {
  name      = "okd-worker"
  type      = "kvm"
  vcpu      = var.worker.cpus
  memory    = var.worker.memory
  autostart = true

  os  = local.domain_os
  cpu = local.cpu_conf

  devices { # CORRECCIÓN
    disk {
      source {
        volume {
          pool   = libvirt_volume.worker_disk.pool
          volume = libvirt_volume.worker_disk.name
        }
      }
      target { # CORRECCIÓN
        dev = "vda"
        bus = "virtio"
      }
    }
    disk {
      source {
        volume {
          pool   = libvirt_volume.worker_ignition.pool
          volume = libvirt_volume.worker_ignition.name
        }
      }
      target { # CORRECCIÓN
        dev = "vdb"
        bus = "virtio"
      }
    }

    interface {
      model { type = "virtio" }
      source { network { network = libvirt_network.okd_net.name } }
      mac { address = var.worker.mac }
    }

    console { # CORRECCIÓN
      type        = "pty"
      target_type = "serial"
      target_port = "0"
    }
  }
}