#cloud-config
hostname: ${hostname}
manage_etc_hosts: false
timezone: ${timezone}

ntp:
  enabled: true
  servers:
    - 10.56.0.1

ssh_pwauth: false
disable_root: false

users:
  - default

  - name: root
    ssh_authorized_keys:
      - ${ssh_keys}

  - name: core
    gecos: "Core User"
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    groups: [wheel]
    shell: /bin/bash
    lock_passwd: false
    ssh_authorized_keys:
      - ${ssh_keys}

###########################################################
# WRITE_FILES
###########################################################

write_files:

  # ---- NetworkManager: IP estática en infra ----
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
      # dejamos que resolv.conf lo gestione cloud-init, no NM
      dns-search=${cluster_name}.${cluster_domain}
      may-fail=false

      [ipv6]
      method=ignore

  # ---- /etc/hosts coherente ----
  - path: /usr/local/bin/set-hosts.sh
    permissions: "0755"
    content: |
      #!/bin/bash
      {
        echo "127.0.0.1   localhost"
        echo "::1         localhost"
        echo "${ip} ${hostname} ${short_hostname}"
      } > /etc/hosts

  # ---- sysctl para forwarding / non-local bind ----
  - path: /etc/sysctl.d/99-custom.conf
    permissions: "0644"
    content: |
      net.ipv4.ip_forward = 1
      net.ipv4.ip_nonlocal_bind = 1
      net.ipv4.conf.all.forwarding = 1

  # ---- NetworkManager: no tocar resolv.conf ----
  - path: /etc/NetworkManager/conf.d/dns.conf
    permissions: "0644"
    content: |
      [main]
      dns=none

  # ---- CoreDNS: configuración principal ----
  - path: /etc/coredns/Corefile
    permissions: "0644"
    content: |
      ${cluster_name}.${cluster_domain}. {
        file /etc/coredns/db.okd
      }

      . {
        forward . 8.8.8.8 1.1.1.1
      }

  # ---- Zona DNS okd.okd.local ----
  - path: /etc/coredns/db.okd
    permissions: "0644"
    content: |
      $ORIGIN ${cluster_name}.${cluster_domain}.
      @   IN SOA dns.${cluster_name}.${cluster_domain}. admin.${cluster_name}.${cluster_domain}. (
              2025010101
              7200
              3600
              1209600
              3600 )
      @           IN NS dns.${cluster_name}.${cluster_domain}.
      dns         IN A ${ip}

      api         IN A ${ip}
      api-int     IN A ${ip}

      bootstrap   IN A 10.56.0.11
      master      IN A 10.56.0.12
      worker      IN A 10.56.0.13

      *.apps      IN A ${ip}

  # ---- Servicio systemd de CoreDNS ----
  - path: /etc/systemd/system/coredns.service
    permissions: "0644"
    content: |
      [Unit]
      Description=CoreDNS
      After=network-online.target
      Wants=network-online.target

      [Service]
      ExecStart=/usr/local/bin/coredns -conf=/etc/coredns/Corefile
      Restart=always
      LimitNOFILE=1048576

      [Install]
      WantedBy=multi-user.target

  # ---- HAProxy para API, MCS e ingress ----
  - path: /etc/haproxy/haproxy.cfg
    permissions: "0644"
    content: |
      global
        maxconn 20000
        daemon

      defaults
        mode tcp
        timeout connect 5s
        timeout client 30s
        timeout server 30s

      # API Kubernetes
      frontend api
        bind 0.0.0.0:6443
        default_backend api_nodes

      backend api_nodes
        balance roundrobin
        option tcp-check
        server bootstrap 10.56.0.11:6443 check fall 3 rise 2
        server master    10.56.0.12:6443 check fall 3 rise 2

      # Machine Config Server (MCS)
      frontend mcs
        bind 0.0.0.0:22623
        default_backend mcs_nodes

      backend mcs_nodes
        balance roundrobin
        # Mientras solo el bootstrap sirve MCS, dejamos solo este.
        server bootstrap 10.56.0.11:22623 check fall 3 rise 2

      # Ingress HTTP/HTTPS hacia el worker
      frontend ingress80
        bind 0.0.0.0:80
        default_backend worker_ingress

      frontend ingress443
        bind 0.0.0.0:443
        default_backend worker_ingress

      backend worker_ingress
        balance roundrobin
        server worker80  10.56.0.13:80  check
        server worker443 10.56.0.13:443 check

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

  # /etc/hosts
  - /usr/local/bin/set-hosts.sh

  # Activar perfil de red estático
  - nmcli connection reload
  - nmcli connection down eth0 || true
  - nmcli connection up eth0

  # Paquetes necesarios
  - dnf install -y firewalld chrony curl tar bind-utils haproxy policycoreutils-python-utils

  # NTP
  - systemctl enable --now chronyd
  - sed -i 's/^pool.*/server 10.56.0.1 iburst/' /etc/chrony.conf
  - echo "allow 10.56.0.0/24" >> /etc/chrony.conf
  - systemctl restart chronyd

  # sysctl
  - sysctl --system

  # 👉 INFRA USA SU PROPIO COREDNS (127.0.0.1)
  - rm -f /etc/resolv.conf
  - printf "nameserver 127.0.0.1\nsearch ${cluster_name}.${cluster_domain}\n" > /etc/resolv.conf

  # CoreDNS binario
  - mkdir -p /etc/coredns
  - curl -L -o /tmp/coredns.tgz https://github.com/coredns/coredns/releases/download/v1.13.1/coredns_1.13.1_linux_amd64.tgz
  - tar -xzf /tmp/coredns.tgz -C /usr/local/bin
  - chmod +x /usr/local/bin/coredns

  # SELinux para HAProxy
  - setsebool -P haproxy_connect_any 1
  - setsebool -P daemons_enable_cluster_mode 1

  # Systemd
  - systemctl daemon-reload
  - systemctl enable firewalld chronyd coredns haproxy
  - systemctl restart firewalld chronyd coredns haproxy

  # Firewall
  - firewall-cmd --permanent --add-port=53/tcp
  - firewall-cmd --permanent --add-port=53/udp
  - firewall-cmd --permanent --add-port=6443/tcp
  - firewall-cmd --permanent --add-port=22623/tcp
  - firewall-cmd --permanent --add-port=80/tcp
  - firewall-cmd --permanent --add-port=443/tcp
  - firewall-cmd --permanent --add-port=9000/tcp
  - firewall-cmd --reload