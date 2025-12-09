✅ DOCUMENTATION_OKD_INFRA.md (Versión Final, Limpia y Consistente)
Infra Node (okd-infra) – DNS, NTP y HAProxy para OKD (Libvirt / KVM)

Este documento describe el funcionamiento del nodo okd-infra (10.56.0.10) en tu laboratorio OKD sobre Libvirt/KVM. Aquí se centralizan:

DNS interno (CoreDNS)

Load Balancer (HAProxy)

NTP (Chrony)

Punto de entrada del tráfico interno del cluster

Incluye topología, nombres de dominio, configuración de CoreDNS, HAProxy, firewall y cómo escalar el clúster.

1. Topología general
1.1. Red y nodos

Red interna Libvirt:

10.56.0.0/24

+--------------------------------------------------------------+
|                   HOST FÍSICO (Rocky Linux)                  |
|             ProLiant DL380 G7 (No AVX → OKD 4.12 OK)         |
|                                                              |
|  Red virtual: okd-net (10.56.0.0/24)                         |
|                                                              |
|   +---------------------+     +---------------------------+  |
|   |  okd-infra          |     |  okd-bootstrap            |  |
|   |  AlmaLinux 9        |     |  Fedora CoreOS 38         |  |
|   |  IP: 10.56.0.10     |     |  IP: 10.56.0.11           |  |
|   |  DNS + HAProxy      |     |  Rol: bootstrap + etcd    |  |
|   +----------+----------+     +---------------------------+  |
|              |                +---------------------------+  |
|              |                |  okd-master               |  |
|              |                |  Fedora CoreOS 38         |  |
|              |                |  IP: 10.56.0.12           |  |
|              |                |  Control-plane            |  |
|              |                +---------------------------+  |
|              |                +---------------------------+  |
|              +---------------->  okd-worker               |  |
|                               |  Fedora CoreOS 38         |  |
|                               |  IP: 10.56.0.13           |  |
|                               |  Worker + Ingress         |  |
|                               +---------------------------+  |
+--------------------------------------------------------------+

1.2. Roles
Nodo	IP	Sistema	Rol
okd-infra	10.56.0.10	AlmaLinux 9	CoreDNS, HAProxy, NTP
okd-bootstrap	10.56.0.11	FCOS	Bootstrap, MCS temporal
okd-master	10.56.0.12	FCOS	Control-plane
okd-worker	10.56.0.13	FCOS	Worker + Ingress
2. Dominios y Nombres Correctos

Tu clúster utiliza:

cluster_domain = "okd.local"
cluster_name   = "okd-lab"


Por tanto, el dominio efectivo es:

okd-lab.okd.local

Nombres críticos para OKD:
Nombre	Apunta a	Función
api.okd-lab.okd.local	10.56.0.10	API Server
api-int.okd-lab.okd.local	10.56.0.10	API interna
*.apps.okd-lab.okd.local	10.56.0.10	Ingress (vía HAProxy)
bootstrap.okd-lab.okd.local	10.56.0.11	Bootstrap
master.okd-lab.okd.local	10.56.0.12	Control-plane
worker.okd-lab.okd.local	10.56.0.13	Worker
3. CoreDNS en okd-infra (10.56.0.10)
3.1. Corefile

Ruta: /etc/coredns/Corefile

okd-lab.${cluster_domain} {
  file /etc/coredns/db.okd
}

. {
  forward . 8.8.8.8 1.1.1.1
}

3.2. Zona DNS (db.okd)

Ruta: /etc/coredns/db.okd

$ORIGIN okd-lab.okd.local.
@   IN SOA dns.okd-lab.okd.local. admin.okd-lab.okd.local. (
        2025010101
        7200
        3600
        1209600
        3600 )

@       IN NS dns.okd-lab.okd.local.
dns     IN A 10.56.0.10

api         IN A 10.56.0.10
api-int     IN A 10.56.0.10

bootstrap   IN A 10.56.0.11
master      IN A 10.56.0.12
worker      IN A 10.56.0.13

*.apps      IN A 10.56.0.10

❗ Corregido

Se ha eliminado el registro conflictivo:

okd-lab IN A 10.56.0.10


Ese registro rompía la instalación (provocaba errores API/MCS).

4. HAProxy en okd-infra

Ruta: /etc/haproxy/haproxy.cfg

global
  maxconn 20000
  daemon

defaults
  mode tcp
  timeout connect 5s
  timeout client 30s
  timeout server 30s

# === API (6443) ===
frontend api
  bind *:6443
  default_backend api_nodes

backend api_nodes
  balance roundrobin
  option tcp-check
  server bootstrap 10.56.0.11:6443 check fall 3 rise 2
  server master    10.56.0.12:6443 check fall 3 rise 2

# === Machine Config Server (22623) ===
frontend mcs
  bind *:22623
  default_backend mcs_nodes

backend mcs_nodes
  balance roundrobin
  server bootstrap 10.56.0.11:22623 check fall 3 rise 2

# === Ingress (80/443) ===
frontend ingress80
  bind *:80
  default_backend worker_ingress

frontend ingress443
  bind *:443
  default_backend worker_ingress

backend worker_ingress
  balance roundrobin
  server worker80  10.56.0.13:80 check
  server worker443 10.56.0.13:443 check

5. Firewall en Infra

Puertos requeridos:

Puerto	Servicio
53 TCP/UDP	CoreDNS
6443 TCP	API
22623 TCP	MCS
80/443 TCP	Apps
opcional: 9000	métricas

Comandos usados:

firewall-cmd --permanent --add-port=53/udp
firewall-cmd --permanent --add-port=53/tcp
firewall-cmd --permanent --add-port=6443/tcp
firewall-cmd --permanent --add-port=22623/tcp
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --reload

6. Flujo del Tráfico (Esquema)
6.1 API Server
Client → api.okd-lab.okd.local → 10.56.0.10 (HAProxy)
    → bootstrap:6443
    → master:6443

6.2 Machine Config Server (MCS)
Node → api-int.okd-lab.okd.local → 10.56.0.10 (HAProxy)
    → bootstrap:22623

6.3 Aplicaciones (*.apps)
Browser → app.apps.okd-lab.okd.local → 10.56.0.10 (HAProxy)
    → worker:80/443

7. Escalar el cluster
7.1 Añadir más masters

Añadir IPs:

master2 → 10.56.0.14
master3 → 10.56.0.15


Actualizar:

CoreDNS
master2 IN A 10.56.0.14
master3 IN A 10.56.0.15

HAProxy
server master2 10.56.0.14:6443 check
server master3 10.56.0.15:6443 check

7.2 Añadir workers
worker2 → 10.56.0.16
worker3 → 10.56.0.17


Actualizar HAProxy:

server worker2 10.56.0.16:80 check
server worker2ssl 10.56.0.16:443 check

8. Pruebas necesarias tras subir una VM
CoreDNS:
dig @10.56.0.10 api.okd-lab.okd.local
dig @10.56.0.10 api-int.okd-lab.okd.local
dig @10.56.0.10 master.okd-lab.okd.local

Servicios:
systemctl status coredns
systemctl status haproxy
systemctl status chronyd

Puertos:
ss -lntp | egrep "53|80|443|6443|22623"

9. Resumen conceptual

Todo el diseño se basa en:

DNS → HAProxy → Nodo correcto (bootstrap/master/worker)


El único punto de entrada es:

10.56.0.10 (okd-infra)


El resto del clúster depende de que este nodo:

resuelva nombres correctamente

distribuya tráfico correctamente

mantenga hora correcta

sea consistente (lo está en este documento)