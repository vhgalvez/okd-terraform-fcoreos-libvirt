# terraform/vm-coreos.tf
###############################################
# FEDORA COREOS DISKS
###############################################

resource "libvirt_volume" "bootstrap_disk" {
  name = "bootstrap.qcow2"
  pool = libvirt_pool.okd.name

  create = {
    content = {
      url = var.coreos_image
    }
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
}

resource "libvirt_volume" "worker_disk" {
  name = "worker.qcow2"
  pool = libvirt_pool.okd.name

  create = {
    content = {
      url = var.coreos_image
    }
  }
}

###############################################
# IGNITION DISKS
###############################################

resource "libvirt_volume" "bootstrap_ignition" {
  name = "bootstrap-ignition.raw"
  pool = libvirt_pool.okd.name

  create = {
    content = {
      url = libvirt_ignition.bootstrap.path
    }
  }
}

resource "libvirt_volume" "master_ignition" {
  name = "master-ignition.raw"
  pool = libvirt_pool.okd.name

  create = {
    content = {
      url = libvirt_ignition.master.path
    }
  }
}

resource "libvirt_volume" "worker_ignition" {
  name = "worker-ignition.raw"
  pool = libvirt_pool.okd.name

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
  name   = "okd-bootstrap"
  memory = var.bootstrap.memory
  vcpu   = var.bootstrap.cpus

  disk {
    volume_id = libvirt_volume.bootstrap_disk.id
  }

  disk {
    volume_id = libvirt_volume.bootstrap_ignition.id
  }

  network_interface {
    network_id = libvirt_network.okd_net.id
    mac        = var.bootstrap.mac
  }

  console {
    type = "pty"
  }
}

###############################################
# MASTER NODE
###############################################

resource "libvirt_domain" "master" {
  name   = "okd-master"
  memory = var.master.memory
  vcpu   = var.master.cpus

  disk {
    volume_id = libvirt_volume.master_disk.id
  }

  disk {
    volume_id = libvirt_volume.master_ignition.id
  }

  network_interface {
    network_id = libvirt_network.okd_net.id
    mac        = var.master.mac
  }

  console {
    type = "pty"
  }
}

###############################################
# WORKER NODE
###############################################

resource "libvirt_domain" "worker" {
  name   = "okd-worker"
  memory = var.worker.memory
  vcpu   = var.worker.cpus

  disk {
    volume_id = libvirt_volume.worker_disk.id
  }

  disk {
    volume_id = libvirt_volume.worker_ignition.id
  }

  network_interface {
    network_id = libvirt_network.okd_net.id
    mac        = var.worker.mac
  }

  console {
    type = "pty"
  }
}
