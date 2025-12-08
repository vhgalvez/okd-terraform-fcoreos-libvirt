# terraform/vm-infra.tf

###############################################
# VM INFRA (HAProxy + CoreDNS)
###############################################
resource "libvirt_domain" "infra" {
  name      = "okd-infra"
  type      = "kvm"
  vcpu      = var.infra.cpus
  memory    = var.infra.memory
  autostart = true

  cpu = {
    mode = "host-passthrough"
  }

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
    boot_devices = [{ dev = "hd" }]
  }

  devices = {
    ############################################
    # DISK DEVICES
    ############################################
    disks = [
      {
        # Disco principal AlmaLinux (vda)
        source = {
          volume = {
            pool   = libvirt_volume.infra_disk.pool
            volume = libvirt_volume.infra_disk.name
          }
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
      },
      {
        # Cloud-init (vdb)
        source = {
          volume = {
            pool   = libvirt_volume.infra_cloudinit.pool
            volume = libvirt_volume.infra_cloudinit.name
          }
        }
        target = {
          dev = "vdb"
          bus = "virtio"
        }
      }
    ]

    ############################################
    # NETWORK INTERFACE
    ############################################
    interfaces = [
      {
        model = { type = "virtio" }
        source = {
          network = { network = libvirt_network.okd_net.name }
        }
        mac = { address = var.infra.mac }
      }
    ]

    ############################################
    # CONSOLE
    ############################################
    consoles = [
      {
        type        = "pty"
        target_type = "serial"
        target_port = "0"
      }
    ]

    ############################################
    # GRAPHICS (VNC PARA ACCESO LOCAL)
    ############################################
    graphics = [
      {
        type = "vnc"
        vnc = {
          autoport = "yes"
          listen = {
            type    = "address"
            address = "127.0.0.1"
          }
        }
      }
    ]

    ############################################
    # VIDEO CARD
    ############################################
    videos = [
      {
        model = {
          type = "qxl"
        }
      }
    ]
  }
}
