#cloud-config
hostname: ${hostname}
manage_etc_hosts: false

ssh_pwauth: true
disable_root: false

users:
  - default

  - name: root
    ssh_authorized_keys: ${ssh_keys}

  - name: core
    gecos: "Core User"
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    groups: [wheel]
    shell: /bin/bash
    lock_passwd: false
    ssh_authorized_keys: ${ssh_keys}

growpart:
  mode: auto
  devices: ["/"]

resize_rootfs: true

###########################################################
# WRITE_FILES
###########################################################

write_files:

  # ──────────────────────────────────────────────
  # NetworkManager (IP estática + DNS primario)
  # ──────────────────────────────────────────────
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
      dns=${dns1};${dns2}
      dns-search=okd-lab.${cluster_domain}
      may-fail=false
      route-metric=10

      [ipv6]
      method=ignore

  # ──────────────────────────────────────────────
  # /etc/hosts gestionado por script
  # ──────────────────────────────────────────────
  - path: /usr/local/bin/set-hosts.sh
    permissions: "0755"
    content: |
      #!/bin/bash
      SHORT=$(echo "${hostname}" | cut -d'.' -f1)
      echo "127.0.0.1   localhost" > /etc/hosts
      echo "::1         localhost" >> /etc/hosts
      echo "${ip}  ${hostname} $SHORT" >> /etc/hosts

  # ──────────────────────────────────────────────
  # sysctl custom (IP forwarding + bind)
  # ──────────────────────────────────────────────
  - path: /etc/sysctl.d/99-custom.conf
    permissions: "0644"
    content: |
      net.ipv4.ip_forward = 1
      net.ipv4.ip_nonlocal_bind = 1

  # ──────────────────────────────────────────────
  # NetworkManager: no modificar resolv.conf
  # ──────────────────────────────────────────────
  - path: /etc/NetworkManager/conf.d/dns.conf
    permissions: "0644"
    content: |
      [main]
      dns=none

  # ──────────────────────────────────────────────
  # CoreDNS: Corefile
  # ──────────────────────────────────────────────
  - path: /etc/coredns/Corefile
    permissions: "0644"
    content: |
      okd-lab.${cluster_domain} {
        file /etc/coredns/db.okd
      }

      . {
        forward . 8.8.8.8 1.1.1.1
      }

  # ──────────────────────────────────────────────
  # CoreDNS: zona DNS interna con LA NUEVA RED 10.56.0.x
  # ──────────────────────────────────────────────
  - path: /etc/coredns/db.okd
    permissions: "0644"
    content: |
      $ORIGIN okd-lab.${cluster_domain}.
      @   IN  SOA dns.okd-lab.${cluster_domain}. admin.okd-lab.${cluster_domain}. (
              2025010101
              7200
              3600
              1209600
              3600 )

      @       IN NS dns.okd-lab.${cluster_domain}.
      dns     IN A ${ip}

      api         IN A 10.56.0.11
      api-int     IN A 10.56.0.11

      bootstrap   IN A 10.56.0.11
      master      IN A 10.56.0.12
      worker      IN A 10.56.0.13

      *.apps      IN A 10.56.0.13

  # ──────────────────────────────────────────────
  # CoreDNS service (systemd)
  # ──────────────────────────────────────────────
  - path: /etc/systemd/system/coredns.service
    permissions: "0644"
    content: |
      [Unit]
      Description=CoreDNS DNS Server
      After=network-online.target
      Wants=network-online.target

      [Service]
      ExecStart=/usr/local/bin/coredns -conf=/etc/coredns/Corefile
      Restart=always
      LimitNOFILE=1048576

      [Install]
      WantedBy=multi-user.target

  # ──────────────────────────────────────────────
  # Chrony — NTP apuntando a la nueva red
  # ──────────────────────────────────────────────
  - path: /etc/chrony.conf
    permissions: "0644"
    content: |
      server 10.56.0.11 iburst prefer
      server 0.pool.ntp.org iburst
      server 1.pool.ntp.org iburst
      server 2.pool.ntp.org iburst
      allow 10.56.0.0/24
      driftfile /var/lib/chrony/drift
      makestep 1.0 3
      bindcmdaddress 0.0.0.0
      bindcmdaddress ::

###########################################################
# RUNCMD — BOOT ORDER CORRECTO
###########################################################

runcmd:

  # Swap
  - fallocate -l 2G /swapfile
  - chmod 600 /swapfile
  - mkswap /swapfile
  - swapon /swapfile
  - echo "/swapfile none swap sw 0 0" >> /etc/fstab

  # Aplicar /etc/hosts
  - /usr/local/bin/set-hosts.sh

  # Reload NetworkManager y aplicar la conexión estática
  - nmcli connection reload
  - bash -c "nmcli connection down eth0 || true"
  - nmcli connection up eth0

  # Instalar paquetes base
  - dnf install -y firewalld resolvconf chrony curl tar bind-utils

  # sysctl
  - sysctl --system

  # resolvconf → resolv.conf real
  - mkdir -p /etc/resolvconf/resolv.conf.d
  - echo "nameserver ${dns1}" > /etc/resolvconf/resolv.conf.d/base
  - echo "nameserver ${dns2}" >> /etc/resolvconf/resolv.conf.d/base
  - echo "search okd-lab.${cluster_domain}" >> /etc/resolvconf/resolv.conf.d/base
  - resolvconf -u

  # CoreDNS instalación
  - mkdir -p /etc/coredns
  - curl -L -o /tmp/coredns.tgz https://github.com/coredns/coredns/releases/download/v1.13.1/coredns_1.13.1_linux_amd64.tgz
  - tar -xzf /tmp/coredns.tgz -C /usr/local/bin
  - rm -f /tmp/coredns.tgz
  - chmod +x /usr/local/bin/coredns

  # Servicios: enable + restart (más robusto que --now)
  - systemctl daemon-reload
  - systemctl enable NetworkManager firewalld chronyd coredns
  - systemctl restart NetworkManager firewalld chronyd coredns

  # Firewall
  - firewall-cmd --permanent --add-port=53/tcp
  - firewall-cmd --permanent --add-port=53/udp
  - firewall-cmd --permanent --add-port=80/tcp
  - firewall-cmd --permanent --add-port=443/tcp
  - firewall-cmd --permanent --add-port=6443/tcp
  - firewall-cmd --permanent --add-port=22623/tcp
  - firewall-cmd --reload

timezone: ${timezone}