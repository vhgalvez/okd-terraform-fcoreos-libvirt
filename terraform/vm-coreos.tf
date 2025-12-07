# terraform/vm-coreos.tf

###############################################
# BASE IMAGE FOR FEDORA COREOS
###############################################
resource "libvirt_volume" "coreos_base" {
  name   = "fcos-base.qcow2"
  pool   = libvirt_pool.okd.name
  format = "qcow2"

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

###############################################################
# BOOTSTRAP NODE
###############################################################
resource "libvirt_domain" "bootstrap" {
  name   = "okd-bootstrap"
  memory = var.bootstrap.memory
  vcpu   = var.bootstrap.cpus
  type   = "kvm"
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
          pool   = libvirt_volume.bootstrap_disk.pool
          volume = libvirt_volume.bootstrap_disk.name
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
      }
    ]

    interfaces = [
      {
        model = {
          type = "virtio"
        }
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

  # IGNITION: nueva sintaxis
  ignition = libvirt_ignition.bootstrap.path
}

###############################################################
# MASTER NODE
###############################################################
resource "libvirt_domain" "master" {
  name   = "okd-master"
  memory = var.master.memory
  vcpu   = var.master.cpus
  type   = "kvm"
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
      }
    ]

    interfaces = [
      {
        model = {
          type = "virtio"
        }
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

  ignition = libvirt_ignition.master.path
}

###############################################################
# WORKER NODE
###############################################################
resource "libvirt_domain" "worker" {
  name   = "okd-worker"
  memory = var.worker.memory
  vcpu   = var.worker.cpus
  type   = "kvm"
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
      }
    ]

    interfaces = [
      {
        model = {
          type = "virtio"
        }
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

  ignition = libvirt_ignition.worker.path
}
