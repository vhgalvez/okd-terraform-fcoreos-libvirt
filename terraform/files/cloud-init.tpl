#cloud-config
hostname: ${hostname}

ssh_authorized_keys:
  - ${ssh_public_key}

network:
  version: 2
  ethernets:
    eth0:
      dhcp4: false
      addresses:
        - ${ip_address}/24
      gateway4: ${gateway}
      nameservers:
        addresses: [${dns1}, ${dns2}]

packages:
  - coredns
  - chrony

runcmd:
  - systemctl enable --now chronyd
  - systemctl enable --now coredns

# Aquí podrías copiar ficheros de config para CoreDNS y Chrony desde
# Terraform usando write_files, pero para la demo lo dejamos simple.
