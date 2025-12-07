# terraform/vm-coreos.tf
###############################################
# BASE IMAGE FOR FEDORA COREOS
# - En 0.9.1 usamos create.content.url
###############################################
resource "libvirt_volume" "coreos_base" {
  name   = "fcos-base.qcow2"
  pool   = libvirt_pool.okd.name
  format = "qcow2"

  create = {
    content = {
      # puede ser ruta local o URL
      url = var.coreos_image
    }
  }
}

###############################################
# VM DISKS (Copy-on-write overlays)
###############################################
resource "libvirt_volume" "bootstrap_disk" {
  name   = "bootstrap.qcow2"
  pool   = libvirt_pool.okd.name
  format = "qcow2"

  backing_store = {
    path   = libvirt_volume.coreos_base.path
    format = "qcow2"
  }
}

resource "libvirt_volume" "master_disk" {
  name   = "master.qcow2"
  pool   = libvirt_pool.okd.name
  format = "qcow2"

  backing_store = {
    path   = libvirt_volume.coreos_base.path
    format = "qcow2"
  }
}

resource "libvirt_volume" "worker_disk" {
  name   = "worker.qcow2"
  pool   = libvirt_pool.okd.name
  format = "qcow2"

  backing_store = {
    path   = libvirt_volume.coreos_base.path
    format = "qcow2"
  }
}

###############################################
# IGNITION (raw) COMO VOLUMEN
# - Siguiendo tu ejemplo de doc:
#   libvirt_ignition -> libvirt_volume create.content.url
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

###############################################################
# BOOTSTRAP NODE (0.9.1 - patrón devices)
###############################################################
resource "libvirt_domain" "bootstrap" {
  name      = "okd-bootstrap"
  type      = "kvm"
  vcpu      = var.bootstrap.cpus
  memory    = var.bootstrap.memory
  autostart = true

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
    boot_devices = ["hd"]
  }

  cpu = {
    mode = "host-passthrough"
  }

  # En 0.9.1 evitamos disk/network_interface/graphics en root
  devices = {
    disks = [
      {
        source = {
          pool   = libvirt_volume.bootstrap_disk.pool
          volume = libvirt_volume.bootstrap_disk.name
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
      },
      {
        source = {
          pool   = libvirt_volume.bootstrap_ignition.pool
          volume = libvirt_volume.bootstrap_ignition.name
        }
        target = {
          dev = "vdb"
          bus = "virtio"
        }
      }
    ]

    interfaces = [
      {
        model = { type = "virtio" }
        source = {
          network = {
            network = libvirt_network.okd_net.name
          }
        }
        mac = var.bootstrap.mac
      }
    ]

    graphics = {
      vnc = {
        listen   = "0.0.0.0"
        autoport = true
      }
    }
  }
}

###############################################################
# MASTER NODE
###############################################################
resource "libvirt_domain" "master" {
  name      = "okd-master"
  type      = "kvm"
  vcpu      = var.master.cpus
  memory    = var.master.memory
  autostart = true

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
    boot_devices = ["hd"]
  }

  cpu = {
    mode = "host-passthrough"
  }

  devices = {
    disks = [
      {
        source = {
          pool   = libvirt_volume.master_disk.pool
          volume = libvirt_volume.master_disk.name
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
      },
      {
        source = {
          pool   = libvirt_volume.master_ignition.pool
          volume = libvirt_volume.master_ignition.name
        }
        target = {
          dev = "vdb"
          bus = "virtio"
        }
      }
    ]

    interfaces = [
      {
        model = { type = "virtio" }
        source = {
          network = {
            network = libvirt_network.okd_net.name
          }
        }
        mac = var.master.mac
      }
    ]

    graphics = {
      vnc = {
        listen   = "0.0.0.0"
        autoport = true
      }
    }
  }
}

###############################################################
# WORKER NODE
###############################################################
resource "libvirt_domain" "worker" {
  name      = "okd-worker"
  type      = "kvm"
  vcpu      = var.worker.cpus
  memory    = var.worker.memory
  autostart = true

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
    boot_devices = ["hd"]
  }

  cpu = {
    mode = "host-passthrough"
  }

  devices = {
    disks = [
      {
        source = {
          pool   = libvirt_volume.worker_disk.pool
          volume = libvirt_volume.worker_disk.name
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
      },
      {
        source = {
          pool   = libvirt_volume.worker_ignition.pool
          volume = libvirt_volume.worker_ignition.name
        }
        target = {
          dev = "vdb"
          bus = "virtio"
        }
      }
    ]

    interfaces = [
      {
        model = { type = "virtio" }
        source = {
          network = {
            network = libvirt_network.okd_net.name
          }
        }
        mac = var.worker.mac
      }
    ]

    graphics = {
      vnc = {
        listen   = "0.0.0.0"
        autoport = true
      }
    }
  }
}
