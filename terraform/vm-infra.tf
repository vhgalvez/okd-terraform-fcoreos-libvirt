# terraform/vm-infra.tf
# terraform/vm-infra.tf (CORREGIDO)

resource "libvirt_volume" "infra_disk" {
  name = "okd-infra.qcow2"
  pool = libvirt_pool.okd.name

  create = {
    content = {
      url = var.almalinux_image
    }
  }
}

data "template_file" "infra_cloud_init" {
  template = file("${path.module}/files/cloud-init-infra.tpl")

  vars = {
    hostname       = var.infra.hostname
    ip             = var.infra.ip
    gateway        = var.gateway
    dns1           = var.dns1
    dns2           = var.dns2
    cluster_name   = var.cluster_name
    cluster_domain = var.cluster_domain
    # Nota: Asegúrese de que join use el formato correcto para su template
    ssh_keys       = join("\n          - ", var.ssh_keys)
    timezone       = var.timezone
  }
}

resource "libvirt_cloudinit_disk" "infra_init" {
  name        = "infra-cloudinit.iso"
  user_data   = data.template_file.infra_cloud_init.rendered

  meta_data = yamlencode({
    instance-id    = "okd-infra"
    local-hostname = var.infra.hostname
  })

  # ✅ CORREGIDO: Se reemplaza el argumento 'pool' por 'pool_name' o simplemente 'pool'.
  # Aunque la documentación anterior permitía 'pool', la v0.9.1 generalmente usa 'pool_name' 
  # para referencias de nombre o sigue el patrón de la v0.7.x. 
  # Dado que se pasó el error "Unsupported argument" en la v0.9.1,
  # usaremos la convención de la v0.7.x donde 'pool' fue reemplazado por 'pool_name' o
  # el argumento fue eliminado si ya está en el path. Sin embargo, para una definición explícita:
  pool_name = libvirt_pool.okd.name
}

resource "libvirt_domain" "infra" {
  name   = "okd-infra"
  vcpu   = var.infra.cpus
  memory = var.infra.memory
  
  # ✅ CORREGIDO: Se agregó el argumento 'type' (requerido)
  type   = "kvm"

  # ✅ CORREGIDO: Se agregó el bloque 'os' para la configuración básica del sistema
  os {
    type = "hvm"
    arch = "x86_64" # Se asume arch
  }

  # ✅ CORREGIDO: 'disk' ahora son bloques anidados
  disk {
    volume_id = libvirt_volume.infra_disk.id
  }

  disk {
    volume_id = libvirt_cloudinit_disk.infra_init.id
  }

  # ✅ CORREGIDO: 'network_interface' ahora es un bloque anidado
  network_interface {
    network_id = libvirt_network.okd_net.id
    mac        = var.infra.mac
    model      = "virtio" # Se asume 'virtio' para rendimiento
  }

  # ✅ CORREGIDO: 'graphics' ahora es un bloque anidado
  graphics {
    type   = "vnc"
    listen = "0.0.0.0"
  }

  autostart = true
}