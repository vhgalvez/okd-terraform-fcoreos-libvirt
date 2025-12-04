#cloud-config
hostname: ${hostname}
manage_etc_hosts: false

ssh_pwauth: true
disable_root: false

users:
  - default
  - name: root
    ssh_authorized_keys: ${ssh_keys}
  - name: infra
    gecos: "Infra Node"
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    groups: [wheel]
    shell: /bin/bash
    lock_passwd: false
    ssh_authorized_keys: ${ssh_keys}

# Expansión de disco automática
growpart:
  mode: auto
  devices: ["/"]
  ignore_growroot_disabled: false

resize_rootfs: true

# Configuración de red (IP estática)
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
      addresses1=${ip}/24,${gateway}
      dns=${dns1};${dns2};
      dns-search=${cluster_domain}
      may-fail=false
      route-metric=10

      [ipv6]
      method=ignore

  - path: /usr/local/bin/set-hosts.sh
    permissions: "0755"
    content: |
      #!/bin/bash
      echo "127.0.0.1   localhost" > /etc/hosts
      echo "::1         localhost" >> /etc/hosts
      echo "${ip}  ${hostname}" >> /etc/hosts

  - path: /etc/coredns/Corefile
    permissions: "0644"
    content: |
      ${cluster_domain} {
        file /etc/coredns/db.okd
      }
      . {
        forward . 8.8.8.8 1.1.1.1
      }

  - path: /etc/coredns/db.okd
    permissions: "0644"
    content: |
      $ORIGIN ${cluster_domain}.
      @   IN  SOA ns1.${cluster_domain}. admin.${cluster_domain}. (
              2025010101 ; serial
              7200       ; refresh
              3600       ; retry
              1209600    ; expire
              3600 )     ; minimum
      @        IN  NS    ns1.${cluster_domain}.
      ns1      IN  A     ${ip}

      api.okd-lab     IN  A   10.17.3.22
      api-int.okd-lab IN  A   10.17.3.22
      bootstrap        IN  A   10.17.3.21
      master           IN  A   10.17.3.22
      worker           IN  A   10.17.3.23
      *.apps           IN  A   10.17.3.23

  - path: /etc/systemd/system/coredns.service
    permissions: "0644"
    content: |
      [Unit]
      Description=CoreDNS DNS Server
      After=network.target

      [Service]
      ExecStart=/usr/bin/coredns -conf=/etc/coredns/Corefile
      Restart=always

      [Install]
      WantedBy=multi-user.target

  - path: /etc/chrony.conf
    permissions: "0644"
    content: |
      server 0.pool.ntp.org iburst
      server 1.pool.ntp.org iburst
      server 2.pool.ntp.org iburst
      allow 10.17.0.0/16
      driftfile /var/lib/chrony/drift
      makestep 1.0 3
      bindcmdaddress 0.0.0.0
      bindcmdaddress ::

  - path: /etc/NetworkManager/conf.d/dns.conf
    permissions: "0644"
    content: |
      [main]
      dns=none

# Comandos que se ejecutan al primer arranque
runcmd:
  # Swap
  - fallocate -l 2G /swapfile
  - chmod 600 /swapfile
  - mkswap /swapfile
  - swapon /swapfile
  - echo "/swapfile none swap sw 0 0" >> /etc/fstab

  # Paquetes base
  - dnf install -y firewalld chrony coredns resolvconf

  # Servicios
  - systemctl enable --now firewalld
  - systemctl enable --now chronyd
  - systemctl enable --now coredns

  # Firewall OKD
  - firewall-cmd --permanent --add-port=53/tcp
  - firewall-cmd --permanent --add-port=53/udp
  - firewall-cmd --permanent --add-port=123/udp
  - firewall-cmd --permanent --add-port=80/tcp
  - firewall-cmd --permanent --add-port=443/tcp
  - firewall-cmd --reload

  # Hostname y red
  - /usr/local/bin/set-hosts.sh
  - resolvconf -u
  - nmcli connection reload
  - nmcli connection down eth0 || true
  - nmcli connection up eth0

timezone: ${timezone}