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

write_files:
  # ── NetworkManager: IP estática en eth0 ──────────────────────────────────────
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
      # OJO: address1 (no addresses1) y sin ; extra al final
      address1=${ip}/24;${gateway}
      dns=${dns1};${dns2}
      dns-search=okd-lab.${cluster_domain}
      may-fail=false
      route-metric=10

      [ipv6]
      method=ignore

  # ── /etc/hosts minimal y consistente ────────────────────────────────────────
  - path: /usr/local/bin/set-hosts.sh
    permissions: "0755"
    content: |
      #!/bin/bash
      cat > /etc/hosts <<EOF
      127.0.0.1   localhost
      ::1         localhost
      ${ip}  ${hostname}
      EOF

  # ── Corefile de CoreDNS ─────────────────────────────────────────────────────
  - path: /etc/coredns/Corefile
    permissions: "0644"
    content: |
      okd-lab.${cluster_domain} {
        file /etc/coredns/db.okd
      }

      . {
        forward . 8.8.8.8 1.1.1.1
      }

  # ── Zona DNS del cluster OKD ────────────────────────────────────────────────
  - path: /etc/coredns/db.okd
    permissions: "0644"
    content: |
      $ORIGIN okd-lab.${cluster_domain}.
      @   IN  SOA dns.okd-lab.${cluster_domain}. admin.okd-lab.${cluster_domain}. (
              2025010101 ; serial
              7200       ; refresh
              3600       ; retry
              1209600    ; expire
              3600 )     ; minimum

      @       IN NS dns.okd-lab.${cluster_domain}.
      dns     IN A ${ip}

      ; API y MCO (inicialmente vía bootstrap)
      api         IN A 10.17.3.21
      api-int     IN A 10.17.3.21

      ; Nodos
      bootstrap   IN A 10.17.3.21
      master      IN A 10.17.3.22
      worker      IN A 10.17.3.23

      ; Apps de ejemplo (ingress)
      *.apps      IN A 10.17.3.23

  # ── Servicio systemd de CoreDNS ─────────────────────────────────────────────
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

  # ── Chrony como servidor NTP local ─────────────────────────────────────────
  - path: /etc/chrony.conf
    permissions: "0644"
    content: |
      server 0.pool.ntp.org iburst
      server 1.pool.ntp.org iburst
      allow 10.17.0.0/16
      driftfile /var/lib/chrony/drift
      makestep 1.0 3

runcmd:
  # Swap (opcional pero útil en AlmaLinux pequeño)
  - [ bash, -c, "fallocate -l 2G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile && echo '/swapfile none swap sw 0 0' >> /etc/fstab" ]

  # Actualizar paquetes base
  - [ dnf, -y, update ]

  # Instalar herramientas necesarias (incluye curl, tar, firewalld, chrony)
  - [ dnf, install, -y, curl, tar, firewalld, chrony ]

  # Preparar directorio de CoreDNS
  - [ mkdir, -p, /etc/coredns ]

  # Descargar y desplegar CoreDNS (binario oficial, versión fija)
  - [ bash, -c, "curl -L -o /tmp/coredns.tgz https://github.com/coredns/coredns/releases/download/v1.13.1/coredns_1.13.1_linux_amd64.tgz" ]
  - [ bash, -c, "tar -xzf /tmp/coredns.tgz -C /usr/local/bin && rm -f /tmp/coredns.tgz" ]
  - [ chmod, "+x", /usr/local/bin/coredns ]

  # Recargar systemd y habilitar servicios
  - [ systemctl, daemon-reload ]
  - [ systemctl, enable, --now, firewalld ]
  - [ systemctl, enable, --now, chronyd ]
  - [ systemctl, enable, --now, coredns ]

  # Reglas de firewall mínimas
  - [ firewall-cmd, --permanent, --add-port=53/tcp ]
  - [ firewall-cmd, --permanent, --add-port=53/udp ]
  - [ firewall-cmd, --permanent, --add-port=123/udp ]
  - [ firewall-cmd, --permanent, --add-port=80/tcp ]
  - [ firewall-cmd, --permanent, --add-port=443/tcp ]
  - [ firewall-cmd, --permanent, --add-port=6443/tcp ]
  - [ firewall-cmd, --permanent, --add-port=22623/tcp ]
  - [ firewall-cmd, --reload ]

  # Aplicar /etc/hosts y recargar red
  - [ /usr/local/bin/set-hosts.sh ]
  - [ nmcli, connection, reload ]
  - [ bash, -c, "nmcli connection down eth0 || true" ]
  - [ nmcli, connection, up, eth0 ]

timezone: ${timezone}