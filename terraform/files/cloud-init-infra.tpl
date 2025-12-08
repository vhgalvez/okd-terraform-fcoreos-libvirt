#cloud-config
hostname: ${hostname}
manage_etc_hosts: false

ssh_pwauth: true
disable_root: false

users:
  - default

  - name: root
    ssh_authorized_keys:
      ${ssh_keys}

  - name: core
    gecos: "Core User"
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    groups: [wheel]
    shell: /bin/bash
    lock_passwd: false
    ssh_authorized_keys:
      ${ssh_keys}

growpart:
  mode: auto
  devices: ["/"]

resize_rootfs: true


###########################################################
# WRITE_FILES
###########################################################

write_files:

  #────────────────────────────────────────────────────────
  # NetworkManager: IP fija + DNS
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
      dns-search=${cluster_name}.${cluster_domain}
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
      echo "127.0.0.1 localhost" > /etc/hosts
      echo "::1       localhost" >> /etc/hosts
      echo "${ip} ${hostname} $SHORT" >> /etc/hosts

  #────────────────────────────────────────────────────────
  # sysctl requerido para OKD
  #────────────────────────────────────────────────────────
  - path: /etc/sysctl.d/99-custom.conf
    permissions: "0644"
    content: |
      net.ipv4.ip_forward = 1
      net.ipv4.ip_nonlocal_bind = 1

  #────────────────────────────────────────────────────────
  # evitar override de resolv.conf
  #────────────────────────────────────────────────────────
  - path: /etc/NetworkManager/conf.d/dns.conf
    permissions: "0644"
    content: |
      [main]
      dns=none

  #────────────────────────────────────────────────────────
  # CoreDNS: zona principal
  #────────────────────────────────────────────────────────
  - path: /etc/coredns/Corefile
    permissions: "0644"
    content: |
      ${cluster_name}.${cluster_domain} {
        file /etc/coredns/db.okd
      }
      . {
        forward . 8.8.8.8 1.1.1.1
      }

  #────────────────────────────────────────────────────────
  # Base de datos DNS OKD
  #────────────────────────────────────────────────────────
  - path: /etc/coredns/db.okd
    permissions: "0644"
    content: |
      $ORIGIN ${cluster_name}.${cluster_domain}.
      @   IN  SOA dns.${cluster_name}.${cluster_domain}. admin.${cluster_name}.${cluster_domain}. (
              2025010101
              7200
              3600
              1209600
              3600 )
      @       IN NS dns.${cluster_name}.${cluster_domain}.
      dns         IN A ${ip}

      api         IN A 10.56.0.11
      api-int     IN A 10.56.0.11

      bootstrap   IN A 10.56.0.11
      master      IN A 10.56.0.12
      worker      IN A 10.56.0.13

      *.apps      IN A 10.56.0.13

  #────────────────────────────────────────────────────────
  # CoreDNS servicio systemd
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

      [Install]
      WantedBy=multi-user.target

  #────────────────────────────────────────────────────────
  # HAProxy configuración OKD
  #────────────────────────────────────────────────────────
  - path: /etc/haproxy/haproxy.cfg
    permissions: "0644"
    content: |
      global
        log /dev/log local0
        maxconn 20000

      defaults
        mode tcp
        log global
        timeout connect 5s
        timeout client 30s
        timeout server 30s

      frontend api
        bind 0.0.0.0:6443
        default_backend api_nodes

      backend api_nodes
        balance roundrobin
        option tcp-check
        server bootstrap 10.56.0.11:6443 check
        server master    10.56.0.12:6443 check

      frontend mcs
        bind 0.0.0.0:22623
        default_backend mcs_nodes

      backend mcs_nodes
        balance roundrobin
        server bootstrap 10.56.0.11:22623 check

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
  - dnf install -y firewalld chrony curl tar bind-utils haproxy policycoreutils-python-utils

  - rm -f /etc/resolv.conf
  - printf "nameserver ${dns1}\nnameserver ${dns2}\nsearch ${cluster_name}.${cluster_domain}\n" > /etc/resolv.conf

  - mkdir -p /etc/coredns
  - curl -L -o /tmp/coredns.tgz https://github.com/coredns/coredns/releases/download/v1.13.1/coredns_1.13.1_linux_amd64.tgz
  - tar -xzf /tmp/coredns.tgz -C /usr/local/bin
  - chmod +x /usr/local/bin/coredns

  # aplicar IP fija de NetworkManager
  - nmcli connection reload
  - nmcli connection up eth0

  - systemctl daemon-reload
  - systemctl enable NetworkManager firewalld chronyd coredns haproxy
  - systemctl restart NetworkManager firewalld chronyd coredns haproxy

  # SELinux FIX
  - setsebool -P haproxy_connect_any 1
  - setsebool -P httpd_can_network_connect 1
  - semanage port -a -t http_port_t -p tcp 6443 || true
  - semanage port -a -t http_port_t -p tcp 22623 || true

  # Firewall OKD
  - firewall-cmd --permanent --add-port=53/tcp
  - firewall-cmd --permanent --add-port=53/udp
  - firewall-cmd --permanent --add-port=80/tcp
  - firewall-cmd --permanent --add-port=443/tcp
  - firewall-cmd --permanent --add-port=6443/tcp
  - firewall-cmd --permanent --add-port=22623/tcp
  - firewall-cmd --reload

timezone: ${timezone}
