
# terraform\terraform.tfvars
# ================================
#  RED
# ================================
network_name = "okd-net"
network_cidr = "10.56.0.0/24"

# ================================
#  IMÁGENES
# ================================
coreos_image    = "/var/lib/libvirt/images/fedora-coreos-41.20250315.3.0-qemu.x86_64.qcow2"
almalinux_image = "/var/lib/libvirt/images/AlmaLinux-9-GenericCloud-9.5-20241120.x86_64.qcow2"

# ================================
#  SSH KEY
# ================================
ssh_keys = [
  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCdfUJjRAJuFcdO0J8CIOkjaKpqP6h9TqDRhZOJTac0199gFUvAJF9R/MAqwDLi2QI6OtYjz1CiCSVLtVQ2fTTIdwVibr+ZKDcbx/E7ivKUUbcmAOU8NP1gv3e3anoUd5k/0h0krP88CXosr41eTih4EcKhBAKbeZ11M0i9GZOux+/WweLtSQ3NU07sUkf1jDIoBungg77unmadqP3m9PUdkFP7tZ2lufcs3iq+vq8JaUBs/hZKNmWOXpnAyNxD9RlBJmvW2QgHmX53y3WC9bWUEUrwfDMB2wAqWPEDfj+5jsXQZcVE4pqD6T1cPaITnr9KFGnCCG1VQg31t1Jttg8z vhgalvez@gmail.com"
]

# ================================
#  SERVIDOR INFRA (DNS + NTP)
# ================================
infra = {
  cpus     = 1
  memory   = 1024
  ip       = "10.56.0.10"
  hostname = "infra.okd.local"
}

# ================================
#  BOOTSTRAP
# ================================
bootstrap = {
  cpus   = 4
  memory = 8192
  ip     = "10.56.0.11"
  mac    = "52:54:00:00:00:11"
}

# ================================
#  MASTER
# ================================
master = {
  cpus   = 
  memory = 6144
  ip     = "10.56.0.12"
  mac    = "52:54:00:00:00:12"
}

# ================================
#  WORKER
# ================================
worker = {
  cpus   = 2
  memory = 8192
  ip     = "10.56.0.13"
  mac    = "52:54:00:00:00:13"
}

# ================================
#  DNS / RED
# ================================
dns1           = "8.8.8.8"
dns2           = "10.56.0.10" # DNS interno (infra)
gateway        = "10.56.0.1"  # Puente virbr_okd
cluster_domain = "cefaslocalserver.com"
timezone       = "UTC"
