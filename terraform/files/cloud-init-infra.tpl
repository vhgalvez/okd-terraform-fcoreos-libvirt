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

growpart:
  mode: auto
  devices: ["/"]
resize_rootfs: true

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
      dns-search=okd-lab.${cluster_domain}
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
      okd-lab.${cluster_domain} {
        file /etc/coredns/db.okd
      }
      . {
        forward . 8.8.8.8 1.1.1.1
      }

  - path: /etc/coredns/db.okd
    permissions: "0644"
    content: |
      $ORIGIN okd-lab.${cluster_domain}.
      @   IN  SOA ns1.okd-lab.${cluster_domain}. admin.okd-lab.${cluster_domain}. (
              2025010101
              7200
              3600
              1209600
              3600 )
      @       IN NS ns1.okd-lab.${cluster_domain}.
      ns1     IN A ${ip}

      api         IN A 10.17.3.22
      api-int     IN A 10.17.3.22
      bootstrap   IN A 10.17.3.21
      master      IN A 10.17.3.22
      worker      IN A 10.17.3.23
      *.apps      IN A 10.17.3.23

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
      allow 10.17.0.0/16
      driftfile /var/lib/chrony/drift
      makestep 1.0 3

runcmd:
  - fallocate -l 2G /swapfile
  - chmod 600 /swapfile
  - mkswap /swapfile
  - swapon /swapfile
  - echo "/swapfile none swap sw 0 0" >> /etc/fstab

  - dnf install -y firewalld chrony coredns

  - systemctl enable --now firewalld chronyd coredns

  - firewall-cmd --permanent --add-port=53/tcp
  - firewall-cmd --permanent --add-port=53/udp
  - firewall-cmd --permanent --add-port=123/udp
  - firewall-cmd --permanent --add-port=80/tcp
  - firewall-cmd --permanent --add-port=443/tcp
  - firewall-cmd --permanent --add-port=6443/tcp
  - firewall-cmd --permanent --add-port=22623/tcp
  - firewall-cmd --reload

  - /usr/local/bin/set-hosts.sh
  - nmcli connection reload
  - nmcli connection down eth0 || true
  - nmcli connection up eth0

timezone: ${timezone}
