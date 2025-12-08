#cloud-config
hostname: ${hostname}
manage_etc_hosts: false

ssh_pwauth: true
disable_root: false

growpart:
  mode: auto
  devices: ["/"]

resize_rootfs: true

users:
  - default

  - name: root
    ssh_authorized_keys:
      ${ssh_keys}

  - name: core
    gecos: "Core User"
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    groups: [wheel, adm]
    shell: /bin/bash
    lock_passwd: false
    ssh_authorized_keys:
      ${ssh_keys}

###########################################################
# NETWORKING — IP FIJA (FUNCIONA 100% EN LIBVIRT 0.8.3)
###########################################################
write_files:
  - path: /etc/NetworkManager/system-connections/eth0.nmconnection
    permissions: "0600"
    content: |
      [connection]
      id=eth0
      type=ethernet
      interface-name=eth0
      autoconnect=true

      [ipv4]
      method=manual
      address1=${ip}/24,${gateway}
      dns=${dns1};${dns2};
      dns-search=${cluster_name}.${cluster_domain}
      may-fail=false

      [ipv6]
      method=ignore

  ###########################################################
  # HOSTS LOCAL
  ###########################################################
  - path: /usr/local/bin/set-hosts.sh
    permissions: "0755"
    content: |
      #!/bin/bash
      SHORT=$(echo "${hostname}" | cut -d'.' -f1)
      echo "127.0.0.1 localhost" > /etc/hosts
      echo "::1       localhost" >> /etc/hosts
      echo "${ip} ${hostname} $SHORT" >> /etc/hosts

  ###########################################################
  # sysctl (OKD)
  ###########################################################
  - path: /etc/sysctl.d/99-custom.conf
    permissions: "0644"
    content: |
      net.ipv4.ip_forward = 1
      net.ipv4.ip_nonlocal_bind = 1

  ###########################################################
  # evitar override de resolv.conf
  ###########################################################
  - path: /etc/NetworkManager/conf.d/dns.conf
    permissions: "0644"
    content: |
      [main]
      dns=none

  ###########################################################
  # resolv.conf real
  ###########################################################
  - path: /etc/resolv.conf
    permissions: "0644"
    content: |
      nameserver ${dns1}
      nameserver ${dns2}
      search ${cluster_name}.${cluster_domain}

  ###########################################################
  # CHRONY (NTP)
  ###########################################################
  - path: /etc/chrony.conf
    permissions: "0644"
    content: |
      server ${dns2} iburst prefer
      allow 10.0.0.0/8
      driftfile /var/lib/chrony/drift
      makestep 1.0 3
      server 0.pool.ntp.org iburst
      server 1.pool.ntp.org iburst
      server 2.pool.ntp.org iburst
      bindcmdaddress 0.0.0.0
      bindcmdaddress ::

###########################################################
# RUNCMD — CONFIG FINAL
###########################################################
runcmd:
  # Swap
  - fallocate -l 4G /swapfile
  - chmod 600 /swapfile
  - mkswap /swapfile
  - swapon /swapfile
  - echo "/swapfile none swap sw 0 0" >> /etc/fstab

  # Paquetes necesarios
  - dnf install -y firewalld chrony NetworkManager

  # Activar servicios
  - systemctl enable --now firewalld chronyd NetworkManager

  # Aplicar hosts
  - /usr/local/bin/set-hosts.sh

  # sysctl
  - sysctl --system

  # Recargar NetworkManager (levanta la IP fija)
  - nmcli connection reload
  - nmcli connection up eth0 || true

  # Firewall básico
  - firewall-cmd --permanent --add-port=22/tcp
  - firewall-cmd --permanent --add-port=443/tcp
  - firewall-cmd --permanent --add-port=6443/tcp
  - firewall-cmd --reload

timezone: ${timezone}
