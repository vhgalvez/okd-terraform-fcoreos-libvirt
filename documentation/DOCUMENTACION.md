# Documentación: okd-terraform-fcoreos-libvirt

Este laboratorio tiene **4 capas lógicas**:

1. **Infraestructura virtual**  
   Terraform + libvirt crean VMs y red.

2. **Servicios básicos**  
   Una VM “infra” provee DNS + NTP.

3. **Configuración de nodos**  
   Ignition (Fedora CoreOS) / cloud-init (infra).

4. **Cluster OKD**  
   `install-config.yaml` + `openshift-install` levantan OpenShift.

---

## 0️⃣ Diseño del laboratorio

Antes de empezar, define:

### 🔹 Nodos

- **infra** → DNS + NTP (AlmaLinux)
- **bootstrap** → arranque de instalación
- **master1** → control plane
- **worker1** → ejecuta pods

### 🔹 Red virtual (ejemplo)

- Nombre: okd-net 
- 10.17.3.0/24  
- bootstrap = "10.56.0.11"
- infra     = "10.56.0.10"
- master    = "10.56.0.12"
- worker    = "10.56.0.13"


### 🔹 Recursos recomendados

| Nodo      | vCPU | RAM      |
|-----------|------|----------|
| infra     | 1    | 2 GB     |
| bootstrap | 2    | 4 GB     |
| master1   | 2    | 6 GB     |
| worker1   | 2    | 8 GB     |

---

## 1️⃣ Capa 1 – Infraestructura: Terraform

Terraform **NO instala OKD** ni genera Ignition.  
Su función:

- Crear pool de almacenamiento en `/var/lib/libvirt/images/okd`
- Crear red virtual NAT (ej: okd-net, 10.17.3.0/24)
- Crear discos de cada VM:
  - Infra → AlmaLinux
  - Bootstrap, Master, Worker → Fedora CoreOS
- Crear VMs:
  - Nombre, vCPU, RAM
  - Conexión a red okd-net
  - Asociación de disco
  - Para FCOS, pasa Ignition como parámetro de arranque

> Terraform = “El arquitecto que crea VMs y red, pero NO sabe nada de OpenShift”.

---

## 2️⃣ Capa 2 – Servicios básicos: nodo infra

OKD requiere desde el inicio:

- **DNS correcto**  
  Resolver:
  - `api.okd-lab.cefaslocalserver.com`
  - `api-int.okd-lab.cefaslocalserver.com`
  - `*.apps.okd-lab.cefaslocalserver.com`
  - Nombres de nodos

- **Tiempo (NTP) correcto**  
  Si el reloj está desfasado:
  - Fallan certificados/tokens
  - etcd se desincroniza

**Solución:**

- VM infra (AlmaLinux)
  - CoreDNS como DNS autoritativo
  - Chrony como NTP para la red

> Resultado: “Cualquier VM del cluster tiene DNS + hora correctos”.

---

## 3️⃣ Capa 3 – Configuración de nodos: Ignition y cloud-init

### 3.1 VM infra (AlmaLinux)

- Configurada con cloud-init (o manual):
  - IP estática
  - hostname
  - clave SSH
  - instalación de CoreDNS + Chrony

### 3.2 VMs Fedora CoreOS (bootstrap, master, worker)

- CoreOS se configura con **Ignition** (no cloud-init):
  - Usuarios, claves
  - Archivos
  - Servicios systemd

> En OKD, **NO escribes Ignition a mano**.  
> Lo genera `openshift-install`.

Terraform **NO crea Ignition**, solo lo inyecta en cada VM.

---

## 4️⃣ Capa 4 – Configuración de OKD: install-config.yaml y openshift-install

- Escribes `install-config.yaml`:
  - nombre del cluster
  - baseDomain
  - red de cluster/servicios
  - plataforma (`none` para bare metal/libvirt)
  - número de masters/workers
  - pullSecret
  - sshKey

- Ejecutas `openshift-install`:
  - Genera manifests internos
  - Genera Ignition para:
    - `bootstrap.ign`
    - `master.ign`
    - `worker.ign`

> Los `.ign` son “recetas de arranque para cada tipo de nodo”.

---

## 5️⃣ Unión de capas: Terraform + Ignition + VMs

- Infraestructura descrita en Terraform
- VM infra definida como Linux normal
- Ignition (`bootstrap.ign`, `master.ign`, `worker.ign`) generados por openshift-install

**Flujo:**

1. Guardas Ignition en carpeta `ignition/`
2. En Terraform, defines recursos `libvirt_ignition`
3. En recursos `libvirt_domain` de bootstrap, master, worker:
   - Indicas Ignition correspondiente

> “Terraform crea las VMs y, a las de CoreOS, les enchufa el Ignition generado por openshift-install.”

---

## 6️⃣ Flujo de instalación de OKD

1. Arranca nodo infra
   - CoreDNS responde a consultas
   - Chrony da la hora
2. Arranca bootstrap (FCOS + bootstrap.ign)
   - Se conecta por DNS
   - Crea el esqueleto del cluster
3. Arranca master (FCOS + master.ign)
   - Se une al cluster
   - API empieza a funcionar
4. Arranca worker (FCOS + worker.ign)
   - Se registra como worker

Cuando termina bootstrap:
- El control plane vive en masters
- El nodo bootstrap se apaga y puede destruirse

El installer termina de:
- Desplegar operadores
- Consola web
- Configurar rutas
- Dejar el cluster “READY”

---

## 7️⃣ Uso, destrucción y recreación

- Usas el cluster (CLI, consola web, despliegue de pods)
- Cuando terminas:
  - Terraform destruye infraestructura (red, VMs, discos)
  - El servidor queda limpio para otros proyectos (ej: K3s)
- Para probar OKD de nuevo:
  - Puedes reutilizar Ignition o generar nuevos
  - Terraform recrea todo

> “OKD es un laboratorio pesado, lo levanto solo para pruebas; K3s es mi cluster diario.”

---

## 8️⃣ Resumen simple

1. Diseñas el lab (nodos, IPs, RAM)
2. Terraform crea red, discos, VMs (infra + bootstrap + master + worker)
3. Nodo infra da DNS y NTP correctos
4. `install-config.yaml` + `openshift-install` generan Ignition
5. Terraform inyecta Ignition en VMs CoreOS
6. Arrancas VMs: infra → bootstrap → master → worker
7. OKD se auto-instala usando Ignition
8. Cuando acabas, Terraform destruye todo y liberas recursos

Alternas entre:
- Cluster K3s (ligero, real)
- Lab OKD (pesado, teórico/práctico)