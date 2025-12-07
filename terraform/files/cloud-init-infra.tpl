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

  #────────────────────────────────────────────────────────
  # NetworkManager — IP estática + DNS interno
  #────────────────────────────────────────────────────────
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
      # Dominio de búsqueda: cluster FQDN + baseDomain
      dns-search=okd.okd.local;okd.local
      may-fail=false
      route-metric=10

      [ipv6]
      method=ignore

  #────────────────────────────────────────────────────────
  # /etc/hosts dinámico
  #────────────────────────────────────────────────────────
  - path: /usr/local/bin/set-hosts.sh
    permissions: "0755"
    content: |
      #!/bin/bash
      SHORT=$(echo "${hostname}" | cut -d'.' -f1)
      echo "127.0.0.1   localhost" > /etc/hosts
      echo "::1         localhost" >> /etc/hosts
      echo "${ip}  ${hostname} $SHORT" >> /etc/hosts

  #────────────────────────────────────────────────────────
  # sysctl — requerido para DNS + API
  #────────────────────────────────────────────────────────
  - path: /etc/sysctl.d/99-custom.conf
    permissions: "0644"
    content: |
      net.ipv4.ip_forward = 1
      net.ipv4.ip_nonlocal_bind = 1

  #────────────────────────────────────────────────────────
  # NetworkManager — no tocar resolv.conf
  #────────────────────────────────────────────────────────
  - path: /etc/NetworkManager/conf.d/dns.conf
    permissions: "0644"
    content: |
      [main]
      dns=none

  #────────────────────────────────────────────────────────
  # CoreDNS — Corefile
  #────────────────────────────────────────────────────────
  - path: /etc/coredns/Corefile
    permissions: "0644"
    content: |
      # Zona interna del clúster: okd.okd.local
      okd.okd.local {
        file /etc/coredns/db.okd
      }
      # El resto de dominios → DNS público
      . {
        forward . 8.8.8.8 1.1.1.1
      }

  #────────────────────────────────────────────────────────
  # CoreDNS — Zona DNS interna OKD
  #────────────────────────────────────────────────────────
  - path: /etc/coredns/db.okd
    permissions: "0644"
    content: |
      $ORIGIN okd.okd.local.
      @   IN  SOA dns.okd.okd.local. admin.okd.okd.local. (
              2025010101 ; serial
              7200       ; refresh
              3600       ; retry
              1209600    ; expire
              3600 )     ; minimum
      @       IN NS dns.okd.okd.local.

      ; Servidor DNS interno (CoreDNS en infra)
      dns         IN A ${ip}

      ; API externa & interna SIEMPRE vía HAProxy en infra
      api         IN A ${ip}
      api-int     IN A ${ip}

      ; Nodos del clúster (IPs reales)
      bootstrap   IN A 10.56.0.11
      master      IN A 10.56.0.12
      worker      IN A 10.56.0.13

      ; Todas las apps también entran por HAProxy (80/443)
      *.apps      IN A ${ip}

  #────────────────────────────────────────────────────────
  # CoreDNS — systemd service
  #────────────────────────────────────────────────────────
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

  #────────────────────────────────────────────────────────
  # HAProxy — load balancer para API, MCS y apps
  #────────────────────────────────────────────────────────
  - path: /etc/haproxy/haproxy.cfg
    permissions: "0644"
    content: |
      global
        log /dev/log local0
        log /dev/log local1 notice
        maxconn 20000
        daemon

      defaults
        mode tcp
        log global
        option tcplog
        timeout connect 5s
        timeout client  30s
        timeout server  30s

      # API Kubernetes / OpenShift
      frontend api
        bind 0.0.0.0:6443
        default_backend api_nodes

      backend api_nodes
        balance roundrobin
        option tcp-check
        # Durante bootstrap:
        #  - bootstrap sirve el API temporal
        # Después:
        #  - master sirve el API definitivo
        server bootstrap 10.56.0.11:6443 check fall 3 rise 2
        server master    10.56.0.12:6443 check fall 3 rise 2

      # Machine Config Server (Ignition)
      frontend mcs
        bind 0.0.0.0:22623
        default_backend mcs_nodes

      backend mcs_nodes
        balance roundrobin
        server bootstrap 10.56.0.11:22623 check fall 3 rise 2

      # Ingress HTTP
      frontend ingress80
        bind 0.0.0.0:80
        default_backend worker_ingress

      # Ingress HTTPS
      frontend ingress443
        bind 0.0.0.0:443
        default_backend worker_ingress

      backend worker_ingress
        balance roundrobin
        server worker80  10.56.0.13:80  check
        server worker443 10.56.0.13:443 check

  #────────────────────────────────────────────────────────
  # Chrony — NTP
  #────────────────────────────────────────────────────────
  - path: /etc/chrony.conf
    permissions: "0644"
    content: |
      server 10.56.0.11 iburst prefer
      allow 10.56.0.0/24
      driftfile /var/lib/chrony/drift
      makestep 1.0 3
      server 0.pool.ntp.org iburst
      server 1.pool.ntp.org iburst
      server 2.pool.ntp.org iburst

###########################################################
# RUNCMD
###########################################################

runcmd:

  # Swap
  - fallocate -l 4G /swapfile
  - chmod 600 /swapfile
  - mkswap /swapfile
  - swapon /swapfile
  - echo "/swapfile none swap sw 0 0" >> /etc/fstab

  # Hosts
  - /usr/local/bin/set-hosts.sh

  # Red
  - nmcli connection reload
  - bash -c "nmcli connection down eth0 || true"
  - nmcli connection up eth0

  # Paquetes necesarios
  - dnf install -y firewalld chrony curl tar bind-utils haproxy policycoreutils-python-utils

  # sysctl
  - sysctl --system

  # resolv.conf estático → usar SIEMPRE CoreDNS local
  - rm -f /etc/resolv.conf
  - printf "nameserver 127.0.0.1\nsearch okd.okd.local okd.local\n" > /etc/resolv.conf

  # CoreDNS
  - mkdir -p /etc/coredns
  - curl -L -o /tmp/coredns.tgz https://github.com/coredns/coredns/releases/download/v1.13.1/coredns_1.13.1_linux_amd64.tgz
  - tar -xzf /tmp/coredns.tgz -C /usr/local/bin
  - chmod +x /usr/local/bin/coredns
  - rm -f /tmp/coredns.tgz

  # SELinux FIX para HAProxy
  - setsebool -P haproxy_connect_any 1
  - setsebool -P httpd_can_network_connect 1
  - semanage port -a -t http_port_t -p tcp 6443 || true
  - semanage port -a -t http_port_t -p tcp 22623 || true

  # Servicios
  - systemctl daemon-reload
  - systemctl enable NetworkManager firewalld chronyd coredns haproxy
  - systemctl restart NetworkManager firewalld chronyd coredns haproxy

  # Firewall OKD
  - firewall-cmd --permanent --add-port=53/tcp
  - firewall-cmd --permanent --add-port=53/udp
  - firewall-cmd --permanent --add-port=80/tcp
  - firewall-cmd --permanent --add-port=443/tcp
  - firewall-cmd --permanent --add-port=6443/tcp
  - firewall-cmd --permanent --add-port=22623/tcp
  - firewall-cmd --reload

timezone: ${timezone}