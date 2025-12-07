
# DOCUMENTATION_OKD_INFRA.md
# Infra Node (okd-infra) – DNS, NTP y HAProxy para OKD en Libvirt

Este documento describe en detalle cómo funciona el **nodo infra (`okd-infra`)** en tu laboratorio OKD sobre KVM/Libvirt, la lógica de nombres y direcciones, el balanceador HAProxy, el DNS interno con CoreDNS y cómo escalar el entorno.  
Incluye **esquemas en ASCII**, explicación de todas las IPs/hostnames y notas para endurecer el firewall (nftables / firewalld).

---

## 1. Topología general del laboratorio

### 1.1. Nodos y direcciones IP

Red interna Libvirt: `10.56.0.0/24`

```text
+--------------------------------------------------------------+
|                   HOST FÍSICO (Rocky Linux)                  |
|                                                              |
|  ProLiant DL380 G7                                           |
|  - /dev/mapper/rl-libvirt_images  -> /var/lib/libvirt/images |
|  - Terraform + Libvirt                                       |
|                                                              |
|  Red libvirt: okd-net (10.56.0.0/24)                         |
|                                                              |
|   +---------------------+     +---------------------------+  |
|   |  okd-infra          |     |  okd-bootstrap            |  |
|   |  AlmaLinux 9        |     |  Fedora CoreOS            |  |
|   |  IP: 10.56.0.10     |     |  IP: 10.56.0.11           |  |
|   |                     |     |  Rol: bootstrap + etcd    |  |
|   |  DNS (CoreDNS)      |     +---------------------------+  |
|   |  NTP (Chrony)       |     +---------------------------+  |
|   |  HAProxy (LB OKD)   |     |  okd-master               |  |
|   +----------+----------+     |  Fedora CoreOS            |  |
|              |                |  IP: 10.56.0.12           |  |
|              |                |  Rol: control-plane       |  |
|              |                +---------------------------+  |
|              |                +---------------------------+  |
|              +---------------->  okd-worker               |  |
|                               |  Fedora CoreOS            |  |
|                               |  IP: 10.56.0.13           |  |
|                               |  Rol: worker + ingress    |  |
|                               +---------------------------+  |
+--------------------------------------------------------------+
```

### 1.2. Resumen de roles

- **okd-infra (10.56.0.10)**  
  - DNS interno de la zona: `okd-lab.${cluster_domain}` (CoreDNS)  
  - NTP local (Chrony)  
  - **HAProxy** como **Load Balancer** para:
    - API del clúster (`:6443`)
    - Machine Config Server (`:22623`)
    - Ingress de aplicaciones (`:80` y `:443`)

- **okd-bootstrap (10.56.0.11)**  
  - Nodo bootstrap (etcd + kube-apiserver temporal)
  - Provee MCS (`:22623`) mientras dura el proceso de instalación
  - kube-apiserver (`:6443`) durante bootstrap

- **okd-master (10.56.0.12)**  
  - Control-plane definitivo después de que se complete la instalación
  - kube-apiserver (`:6443`)

- **okd-worker (10.56.0.13)**  
  - Nodo de trabajo
  - Termina alojando routers/ingress de OpenShift  
  - Se expone a través de HAProxy para `*.apps`

---

## 2. Lógica de nombres y dominios

### 2.1. Variables principales de Terraform

En `terraform.tfvars`:

```hcl
# Red
network_name    = "okd-net"
network_cidr    = "10.56.0.0/24"

# Nodo infra
infra = {
  cpus     = 1
  memory   = 2048
  ip       = "10.56.0.10"
  hostname = "infra.okd.local"
}

# Bootstrap, master, worker
bootstrap = {
  cpus   = 6
  memory = 14336
  ip     = "10.56.0.11"
  mac    = "52:54:00:00:00:11"
}

master = {
  cpus   = 4
  memory = 12288
  ip     = "10.56.0.12"
  mac    = "52:54:00:00:00:12"
}

worker = {
  cpus   = 2
  memory = 4096
  ip     = "10.56.0.13"
  mac    = "52:54:00:00:00:13"
}

# DNS / gateway / dominio OKD
dns1           = "8.8.8.8"
dns2           = "10.56.0.10"                  # ← okd-infra
gateway        = "10.56.0.1"
cluster_domain = "cefaslocalserver.com"
timezone       = "UTC"
```

### 2.2. Dominio lógico del clúster

- **Dominio global del clúster:**  
  `okd-lab.${cluster_domain}` → `okd-lab.cefaslocalserver.com`

- **API externas de OKD/Openshift:**  
  - `api.okd-lab.cefaslocalserver.com`
  - `api-int.okd-lab.cefaslocalserver.com`
- **Wildcard de aplicaciones:**  
  - `*.apps.okd-lab.cefaslocalserver.com`  

Todos estos nombres se resuelven a IPs internas (10.56.0.x) mediante **CoreDNS** corriendo en `okd-infra`.

---

## 3. CoreDNS – DNS interno del clúster

### 3.1. Fichero `Corefile`

Ruta: `/etc/coredns/Corefile` (en `okd-infra`)

```bash
okd-lab.${cluster_domain} {
  file /etc/coredns/db.okd
}

. {
  forward . 8.8.8.8 1.1.1.1
}
```

**Explicación:**
- Primer bloque: sirve la zona **autoritativa** `okd-lab.${cluster_domain}` desde el archivo `db.okd`.
- Segundo bloque: cualquier otro dominio (.) se **reenvía** a DNS públicos (8.8.8.8, 1.1.1.1).

### 3.2. Fichero de zona `db.okd`

Ruta: `/etc/coredns/db.okd`

```text
$ORIGIN okd-lab.${cluster_domain}.
@   IN  SOA dns.okd-lab.${cluster_domain}. admin.okd-lab.${cluster_domain}. (
        2025010101  ; Serial
        7200        ; Refresh
        3600        ; Retry
        1209600     ; Expire
        3600 )      ; Minimum TTL

@       IN NS dns.okd-lab.${cluster_domain}.
dns     IN A ${ip}           ; 10.56.0.10 (okd-infra)

api         IN A ${ip}       ; HAProxy → 6443
api-int     IN A ${ip}       ; HAProxy → 6443

bootstrap   IN A 10.56.0.11
master      IN A 10.56.0.12
worker      IN A 10.56.0.13

*.apps      IN A ${ip}       ; HAProxy → 80/443
```

> **Nota:** `${ip}` en la plantilla se sustituye por `10.56.0.10` (IP de `okd-infra`).

### 3.3. Esquema ASCII de resolución DNS

```text
   Consulta: api.okd-lab.cefaslocalserver.com

   Nodo OKD (bootstrap/master/worker)
            |
            v
   +--------------------+
   |  DNS: 10.56.0.10   |  (dns2 en NetworkManager)
   |  CoreDNS           |
   +--------------------+
            |
            v
  api.okd-lab.cefaslocalserver.com  ->  10.56.0.10 (okd-infra)
```

Luego el tráfico TCP llega a HAProxy en `okd-infra` (ver sección 4).

---

## 4. HAProxy – Load Balancer de OKD

HAProxy se instala y configura en `okd-infra`.

### 4.1. Fichero de configuración `haproxy.cfg`

Ruta: `/etc/haproxy/haproxy.cfg`

```cfg
global
  log /dev/log local0
  maxconn 20000
  daemon

defaults
  mode tcp
  log global
  timeout connect 5s
  timeout client 30s
  timeout server 30s

# === API Server (6443) ===
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

# === Ingress (apps: 80 / 443) ===
frontend ingress80
  bind *:80
  default_backend worker_ingress

frontend ingress443
  bind *:443
  default_backend worker_ingress

backend worker_ingress
  balance roundrobin
  server worker80  10.56.0.13:80  check
  server worker443 10.56.0.13:443 check
```

### 4.2. Flujo de tráfico – Esquemas ASCII

#### 4.2.1. API (`:6443`)

```text
kubectl / installer / openshift-install
       |
       v
api.okd-lab.cefaslocalserver.com:6443
       |
 DNS → 10.56.0.10 (okd-infra)
       |
       v
+-------------------+
|   HAProxy (api)   |
|   10.56.0.10:6443 |
+-------------------+
   |            |
   v            v
10.56.0.11   10.56.0.12
bootstrap    master
:6443        :6443
```

#### 4.2.2. Machine Config Server (`:22623`)

```text
Nodos CoreOS (bootstrap/master/worker)
       |
       v
api-int.okd-lab.cefaslocalserver.com:22623
       |
 DNS → 10.56.0.10
       |
       v
+--------------------+
|  HAProxy (mcs)     |
|  10.56.0.10:22623  |
+--------------------+
           |
           v
   10.56.0.11:22623 (bootstrap)
```

> En fases posteriores, podrías añadir el master también como servidor MCS, según la versión de OKD.

#### 4.2.3. Ingress aplicaciones (`:80` y `:443`)

```text
Browser usuario (externo/interno)
          |
   app1.apps.okd-lab.cefaslocalserver.com
          |
          v
   DNS → 10.56.0.10
          |
          v
+----------------------+
| HAProxy ingress80/443|
| 10.56.0.10:80/443    |
+----------------------+
          |
          v
   okd-worker 10.56.0.13:80/443
   (routers / ingress)
```

---

## 5. Cloud-init del nodo INFRA (AlmaLinux)

El cloud-init que usas en `okd-infra` incluye:

- Configuración de **NetworkManager** con IP estática, DNS y búsqueda de dominio.
- Script `set-hosts.sh` para gestionar `/etc/hosts` basado en `${hostname}` y `${ip}`.
- `sysctl` para:
  - `net.ipv4.ip_forward = 1` (permite forwarding si más adelante haces routing)
  - `net.ipv4.ip_nonlocal_bind = 1` (necesario para ciertos escenarios de HAProxy/VIP)
- Configuración de **CoreDNS** (`Corefile` + `db.okd`).
- Configuración de **HAProxy** (fichero completo).
- Configuración de **Chrony** (`/etc/chrony.conf`).
- Instalación de paquetes necesarios: `firewalld`, `resolvconf`, `chrony`, `curl`, `tar`, `bind-utils`, `haproxy`.
- Habilitación de servicios vía `systemctl enable ...`.

### 5.1. Ports abiertos en el firewall

En la sección `runcmd` se abren estos puertos con **firewalld**:

```bash
firewall-cmd --permanent --add-port=53/tcp
firewall-cmd --permanent --add-port=53/udp
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --permanent --add-port=6443/tcp
firewall-cmd --permanent --add-port=22623/tcp
firewall-cmd --reload
```

> **Opcional hardening:** más adelante, puedes limitar estos puertos a la red `10.56.0.0/24` con zonas de firewalld o reglas nftables.

---

## 6. Escalado y evolución del laboratorio

### 6.1. Escalado de control-plane

Ahora mismo tienes:

- 1 master (`okd-master`, 10.56.0.12)
- 1 bootstrap (`okd-bootstrap`, 10.56.0.11) – temporal
- 1 infra/worker (`okd-worker`, 10.56.0.13 – rol worker + ingress)

Para acercarte a un entorno más **HA real**:

1. Añadir **2 masters adicionales** (total 3 control-plane):  
   - `okd-master-2` → 10.56.0.14  
   - `okd-master-3` → 10.56.0.15  
2. Actualizar:
   - Zona DNS (`db.okd`): registros `master2`, `master3`  
   - HAProxy:
     - Añadir `server master2` y `server master3` en `backend api_nodes`.

Esquema:

```text
            +-------------------------+
            |   HAProxy (API 6443)   |
            |   10.56.0.10           |
            +-----------+-------------+
                        |
        +---------------+-----------------------+
        v               v                       v
 10.56.0.12        10.56.0.14             10.56.0.15
 okd-master-1      okd-master-2           okd-master-3
```

### 6.2. Escalado de workers / routers

- Añadir nuevos workers:
  - `okd-worker-2` → 10.56.0.16  
  - `okd-worker-3` → 10.56.0.17  
- Actualizar `db.okd` para que:
  - `*.apps` apunte al HAProxy (10.56.0.10) como ya tienes.
- Actualizar HAProxy `worker_ingress`:

```cfg
backend worker_ingress
  balance roundrobin
  server worker1 10.56.0.13:80  check
  server worker1ssl 10.56.0.13:443 check
  server worker2 10.56.0.16:80  check
  server worker2ssl 10.56.0.16:443 check
  server worker3 10.56.0.17:80  check
  server worker3ssl 10.56.0.17:443 check
```

---

## 7. Nftables / Firewalld – Consideraciones

Actualmente usas **firewalld** en el nodo infra y abres puertos de forma global. Para endurecerlo:

1. **Limitar acceso solo a la red 10.56.0.0/24**:
   - Crear zona específica (`okd`) en firewalld y asignar la interfaz.
   - Añadir puertos solo en esa zona.
2. O bien pasar a **nftables** con reglas explícitas:

Ejemplo conceptual (no aplicado aún):

```bash
table inet filter {
  chain input {
    type filter hook input priority 0;
    policy drop;

    # Permitir lo básico
    ct state established,related accept
    iif "lo" accept

    # Permitir desde la red OKD
    ip saddr 10.56.0.0/24 tcp dport { 53,80,443,6443,22623 } accept
    ip saddr 10.56.0.0/24 udp dport 53 accept

    # ICMP para debugging
    ip protocol icmp accept
  }
}
```

> Esto te ayuda a tener un **infra node bastante cerrado**, aceptando solo tráfico del segmento del clúster.

---

## 8. Resumen mental (cómo pensar el sistema)

1. **Infra (10.56.0.10)** es tu **“punto central”**:
   - DNS interno (CoreDNS) decide **qué nombre → qué IP**.
   - HAProxy decide **a qué nodo concreto** mandarle el tráfico:
     - API (`:6443`) → bootstrap/master(s)
     - MCS (`:22623`) → bootstrap
     - Apps (`:80/443`) → worker(s)
   - Chrony da **hora coherente** a todos.

2. **Todos los nodos OKD** (bootstrap/master/worker) usan:
   - `dns2 = 10.56.0.10` para resolver `okd-lab.${cluster_domain}`.
   - Así, **siempre** pasan por `okd-infra` para descubrir API, MCS, Apps.

3. Cuando el clúster madura:
   - **Bootstrap** desaparece → HAProxy puede quedarse con `master` solo en backend.
   - Escalas masters/workers simplemente **añadiendo servidores** en HAProxy y registros en `db.okd`.

4. Desde fuera del clúster (si lo expones):
   - Puedes hacer que el **host físico** o tu router doméstico apunten `api.okd-lab...` y `*.apps` a la IP del `okd-infra` en la LAN externa (NAT / port-forward).

Con esta visión, tu “mapa mental” es:

```text
Nombres  →  CoreDNS (10.56.0.10)  →  IP 10.56.0.10  →  HAProxy  →  Nodos OKD
```

Todo pasa por **un solo “cerebro de red”**: `okd-infra`.

---

## 9. Checklist rápido

- [x] `okd-infra` con IP fija `10.56.0.10` y hostname `infra.okd.local`
- [x] CoreDNS sirviendo `okd-lab.${cluster_domain}`
- [x] HAProxy escuchando en `:80`, `:443`, `:6443`, `:22623`
- [x] Firewalld con puertos abiertos para DNS, API, MCS, Apps
- [x] Todos los nodos OKD usando `10.56.0.10` como DNS secundario (`dns2`)
- [x] `api` / `api-int` / `*.apps` apuntando a `10.56.0.10`
- [x] Plan de escalado definido para masters y workers

Con esto tienes una **infraestructura de red sólida, entendible y escalable** para tu laboratorio OKD sobre KVM/Libvirt.




# 1) Ver si cloud-init dejó los archivos
ls -l /etc/coredns
ls -l /etc/haproxy

# 2) Servicios
sudo systemctl status chronyd
sudo systemctl status haproxy
sudo systemctl status coredns


# 3) Puertos escuchando
sudo ss -lntp | egrep '53|80|443|6443|22623'

# 4) DNS desde infra
dig @10.56.0.10 api.okd-lab.cefaslocalserver.com
dig @10.56.0.10 bootstrap.okd-lab.cefaslocalserver.com
dig @10.56.0.10 api.okd-lab.cefaslocalserver.com