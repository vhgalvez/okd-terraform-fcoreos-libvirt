# terraform/vm-coreos.tf
###############################################
# DISK IMAGES FOR FEDORA COREOS (ONE PER NODE)
###############################################

# Cada nodo tendrá su propio disco QCOW2 creado
# directamente a partir de la imagen oficial de Fedora CoreOS.
# Esto evita problemas con backing_store y garantiza que el
# disco sea bootable.

resource "libvirt_volume" "bootstrap_disk" {
  name = "bootstrap.qcow2"
  pool = libvirt_pool.okd.name

  # Crea el volumen copiando la imagen base de CoreOS
  create = {
    content = {
      url = var.coreos_image
    }
  }

  target = {
    format = { type = "qcow2" }
  }
}

resource "libvirt_volume" "master_disk" {
  name = "master.qcow2"
  pool = libvirt_pool.okd.name

  create = {
    content = {
      url = var.coreos_image
    }
  }

  target = {
    format = { type = "qcow2" }
  }
}

resource "libvirt_volume" "worker_disk" {
  name = "worker.qcow2"
  pool = libvirt_pool.okd.name

  create = {
    content = {
      url = var.coreos_image
    }
  }

  target = {
    format = { type = "qcow2" }
  }
}

###############################################
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

  create = {
    content = { url = libvirt_ignition.bootstrap.path }
  }

  target = {
    format = { type = "raw" }
  }
}

resource "libvirt_volume" "master_ignition" {
  name = "master-ignition.raw"
  pool = libvirt_pool.okd.name

  create = {
    content = { url = libvirt_ignition.master.path }
  }

  target = {
    format = { type = "raw" }
  }
}

resource "libvirt_volume" "worker_ignition" {
  name = "worker-ignition.raw"
  pool = libvirt_pool.okd.name

  create = {
    content = { url = libvirt_ignition.worker.path }
  }

  target = {
    format = { type = "raw" }
  }
}

###############################################
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

###############################################
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

  devices = {
    disks = [
      {
        # Disco principal de Fedora CoreOS (bootable)
        source = {
          volume = {
            pool   = libvirt_volume.bootstrap_disk.pool
            volume = libvirt_volume.bootstrap_disk.name
          }
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
      },
      {
        # Segundo disco: Ignition
        source = {
          volume = {
            pool   = libvirt_volume.bootstrap_ignition.pool
            volume = libvirt_volume.bootstrap_ignition.name
          }
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
          network = { network = libvirt_network.okd_net.name }
        }
        mac = { address = var.bootstrap.mac }
      }
    ]

    consoles = [
      {
        type        = "pty"
        target_type = "serial"
        target_port = "0"
      }
    ]
  }
}

###############################################
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

  devices = {
    disks = [
      {
        source = {
          volume = {
            pool   = libvirt_volume.master_disk.pool
            volume = libvirt_volume.master_disk.name
          }
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
      },
      {
        source = {
          volume = {
            pool   = libvirt_volume.master_ignition.pool
            volume = libvirt_volume.master_ignition.name
          }
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
          network = { network = libvirt_network.okd_net.name }
        }
        mac = { address = var.master.mac }
      }
    ]

    consoles = [
      {
        type        = "pty"
        target_type = "serial"
        target_port = "0"
      }
    ]
  }
}

###############################################
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

  devices = {
    disks = [
      {
        source = {
          volume = {
            pool   = libvirt_volume.worker_disk.pool
            volume = libvirt_volume.worker_disk.name
          }
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
      },
      {
        source = {
          volume = {
            pool   = libvirt_volume.worker_ignition.pool
            volume = libvirt_volume.worker_ignition.name
          }
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
          network = { network = libvirt_network.okd_net.name }
        }
        mac = { address = var.worker.mac }
      }
    ]

    consoles = [
      {
        type        = "pty"
        target_type = "serial"
        target_port = "0"
      }
    ]
  }
}
