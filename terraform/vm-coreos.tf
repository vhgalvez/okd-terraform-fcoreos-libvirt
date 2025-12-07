# terraform/vm-coreos.tf

# terraform/vm-coreos.tf (CORREGIDO)

###############################################
# BASE IMAGE FOR FEDORA COREOS
###############################################
resource "libvirt_volume" "coreos_base" {
  name = "fcos-base.qcow2"
  pool = libvirt_pool.okd.name

  # La sintaxis de 'create' es correcta y se mantiene.
  create = {
    content = {
      url = var.coreos_image
    }
  }
}

###############################################
# VM DISKS (Copy-on-write overlays)
###############################################
# Estos recursos libvirt_volume son correctos y se mantienen.
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
# IGNITION DISKS (MUST FOLLOW DOCUMENTATION)
###############################################
# Estos recursos libvirt_volume son correctos y se mantienen.
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
  
  # ✅ CORREGIDO: Se agregó el argumento 'type' (requerido en v0.9.1)
  type    = "kvm" 

  # ✅ CORREGIDO: Se reemplazan 'machine' y 'arch' por el bloque 'os'
  os {
    type = "hvm"
    arch = "x86_64"
    machine = "q35"
  }

  # ✅ CORREGIDO: 'disk' ahora son bloques anidados
  disk { 
    volume_id = libvirt_volume.bootstrap_disk.id 
  }
  disk { 
    volume_id = libvirt_volume.bootstrap_ignition.id 
  }

  # ✅ CORREGIDO: 'network_interface' ahora es un bloque anidado
  network_interface {
    network_id = libvirt_network.okd_net.id
    mac        = var.bootstrap.mac
    model      = "virtio"
  }

  # ✅ CORREGIDO: 'graphics' ahora es un bloque anidado
  graphics {
    type   = "vnc"
    listen = "0.0.0.0"
  }

  autostart = true
}

###############################################
# MASTER NODE
###############################################
resource "libvirt_domain" "master" {
  name    = "okd-master"
  vcpu    = var.master.cpus
  memory  = var.master.memory
  
  # ✅ CORREGIDO: Se agregó el argumento 'type'
  type    = "kvm"

  # ✅ CORREGIDO: Bloque 'os'
  os {
    type = "hvm"
    arch = "x86_64"
    machine = "q35"
  }

  # ✅ CORREGIDO: Bloques 'disk'
  disk { 
    volume_id = libvirt_volume.master_disk.id 
  }
  disk { 
    volume_id = libvirt_volume.master_ignition.id 
  }

  # ✅ CORREGIDO: Bloque 'network_interface'
  network_interface {
    network_id = libvirt_network.okd_net.id
    mac        = var.master.mac
    model      = "virtio"
  }

  # ✅ CORREGIDO: Bloque 'graphics'
  graphics {
    type   = "vnc"
    listen = "0.0.0.0"
  }

  autostart = true
}

###############################################
# WORKER NODE
###############################################
resource "libvirt_domain" "worker" {
  name    = "okd-worker"
  vcpu    = var.worker.cpus
  memory  = var.worker.memory
  
  # ✅ CORREGIDO: Se agregó el argumento 'type'
  type    = "kvm"

  # ✅ CORREGIDO: Bloque 'os'
  os {
    type = "hvm"
    arch = "x86_64"
    machine = "q35"
  }

  # ✅ CORREGIDO: Bloques 'disk'
  disk { 
    volume_id = libvirt_volume.worker_disk.id 
  }
  disk { 
    volume_id = libvirt_volume.worker_ignition.id 
  }

  # ✅ CORREGIDO: Bloque 'network_interface'
  network_interface {
    network_id = libvirt_network.okd_net.id
    mac        = var.worker.mac
    model      = "virtio"
  }

  # ✅ CORREGIDO: Bloque 'graphics'
  graphics {
    type   = "vnc"
    listen = "0.0.0.0"
  }

  autostart = true
}