# Ignition, install-config y flujo de instalación de OKD  
_repo: `okd-terraform-fcoreos-libvirt`_

Este documento explica, **ordenado y corregido**, cómo se conectan:

- `install-config.yaml`
- `openshift-install`
- Ignition (`bootstrap.ign`, `master.ign`, `worker.ign`)
- Terraform + libvirt + Fedora CoreOS

---

## 1. Ignition: idea general

En este laboratorio:

- Las VMs de **Fedora CoreOS** (bootstrap, master, worker) **NO usan cloud-init**.
- Se configuran con **Ignition**, que es un JSON que describe:
  - usuarios y claves
  - ficheros a escribir
  - servicios systemd a habilitar
  - etc.

> **Importante:**  
> Los archivos Ignition para OKD **NO se escriben a mano**.  
> Los genera `openshift-install` a partir de `install-config/install-config.yaml`.

---

## 2. Generar Ignition con `openshift-install`

Asumiendo esta estructura:

```text
okd-terraform-fcoreos-libvirt/
├── install-config/
│   └── install-config.yaml
└── terraform/
    └── ...
```

Ejecuta:

```bash
cd install-config

# (opcional) ver/validar manifests
openshift-install create manifests --dir=.

# generar Ignition
openshift-install create ignition-configs --dir=.
```

Esto creará dentro de `install-config/`:

- `bootstrap.ign`
- `master.ign`
- `worker.ign`

Opcionalmente puedes copiarlos a una carpeta `ignition/`:

```bash
mkdir -p ../ignition
cp bootstrap.ign master.ign worker.ign ../ignition/
```

Terraform luego inyectará esos `.ign` en las VMs de Fedora CoreOS.

---

## 3. `install-config/install-config.yaml` (plantilla base corregida)

Este es un ejemplo adaptado a tu laboratorio.  
Debes ajustar:

- dominio (`baseDomain`)
- red (`machineNetwork`)
- `pullSecret`
- `sshKey`

```yaml
apiVersion: v1
baseDomain: cefaslocalserver.com
metadata:
  name: okd-lab

networking:
  networkType: OpenShiftSDN
  clusterNetwork:
    - cidr: 10.128.0.0/14
      hostPrefix: 23
  serviceNetwork:
    - 172.30.0.0/16

# Red física/virtual donde viven tus nodos (libvirt)
machineNetwork:
  - cidr: 10.17.3.0/24

platform:
  none: {}

# Laboratorio con 1 master (oficialmente son 3, pero para lab vale)
controlPlane:
  hyperthreading: Enabled
  name: master
  replicas: 1

compute:
  - hyperthreading: Enabled
    name: worker
    replicas: 1

# Para OKD (comunidad), se puede usar "{}"
# Si estás usando OpenShift de Red Hat: sustituir por tu pullSecret real
pullSecret: "{}"

# Sustituir por tu clave real
sshKey: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDC9X... vhgalvez@gmail.com"
```

**Notas importantes sobre este archivo:**

- `platform: none`: Obligatorio cuando NO usas AWS, Azure, GCP, vSphere, etc. (bare metal/libvirt/homelab).
- `replicas: 1`: Documentación oficial recomienda 3 masters. Para laboratorio con pocos recursos, usar 1 funciona bien.
- `machineNetwork.cidr`: Debe coincidir con la red de tus VMs en libvirt. En tu caso: `10.17.3.0/24`.
- `pullSecret`: OKD (comunidad): `pullSecret: "{}"` es válido. OpenShift (Red Hat): usa una pull secret real.

Después de crear este archivo, siempre:

```bash
cd install-config
openshift-install create manifests --dir=.
openshift-install create ignition-configs --dir=.
```

Obtendrás:

- `bootstrap.ign`
- `master.ign`
- `worker.ign`

---

## 4. Cómo usa Terraform estos .ign (visión conceptual)

Terraform describe la infraestructura en `terraform/`:

- red (`network.tf`)
- pool de volúmenes
- VMs:
  - infra (AlmaLinux + cloud-init)
  - bootstrap (FCOS + Ignition)
  - master (FCOS + Ignition)
  - worker (FCOS + Ignition)

En los ficheros de Terraform (`vm-coreos.tf` + `ignition.tf`):

- Se leen los archivos `.ign` generados por `openshift-install`.
- Se crean recursos tipo `libvirt_ignition` (o equivalente).
- Cada `libvirt_domain` (bootstrap/master/worker) recibe su Ignition.

**Resultado:**  
Cuando arranca la VM FCOS, lee Ignition y sabe:

- si es bootstrap, master o worker
- a qué cluster unirse
- cómo configurar servicios base

---

## 5. Butane (opcional): jugar con FCOS fuera de OKD

Butane convierte `.bu` → `.ign`.  
Es útil si quieres probar FCOS sin OKD, pero NO es obligatorio para este lab.

Ejemplo `butane/bootstrap.bu`:

```yaml
variant: fcos
version: 1.5.0
storage:
  files:
    - path: /etc/hostname
      mode: 0644
      contents:
        inline: "okd-bootstrap"
passwd:
  users:
    - name: core
      ssh_authorized_keys:
        - ssh-rsa AAAA... tu clave ...
```

Makefile simple:

```makefile
BINARY=butane

all: bootstrap master worker

bootstrap:
	$(BINARY) bootstrap.bu > ../ignition/bootstrap.ign

master:
	$(BINARY) master.bu > ../ignition/master.ign

worker:
	$(BINARY) worker.bu > ../ignition/worker.ign
```

> Para un lab de OKD puro, lo normal es usar los Ignition generados por `openshift-install`, no Butane manual.

---

## 6. Mini README para la raíz del repo

Puedes usar esto (o adaptarlo) como `README.md` principal:

```markdown
# okd-terraform-fcoreos-libvirt

Laboratorio de OKD (OpenShift Origin) sobre Fedora CoreOS y libvirt/KVM, orquestado con Terraform.  
Diseñado para homelabs con recursos limitados:

- 1 nodo **infra** (AlmaLinux: DNS + NTP)
- 1 nodo **bootstrap** (Fedora CoreOS)
- 1 nodo **master** (Fedora CoreOS)
- 1 nodo **worker** (Fedora CoreOS)

## Flujo resumido

1. Preparar imágenes:
   - Fedora CoreOS qcow2 (`fedora-coreos-*.qcow2`)
   - AlmaLinux GenericCloud qcow2 (`AlmaLinux-9-GenericCloud-*.qcow2`)

2. Editar `terraform/terraform.tfvars` con:
   - rutas de imágenes (`coreos_image`, `so_image`)
   - IPs / MACs
   - clave SSH pública

3. Crear `install-config/install-config.yaml` y generar Ignition:

   ```bash
   cd install-config
   openshift-install create manifests --dir=.
   openshift-install create ignition-configs --dir=.
   ```

   Copiar (o referenciar) los .ign:

   - install-config/bootstrap.ign
   - install-config/master.ign
   - install-config/worker.ign

   O copiarlos a `ignition/` si tu Terraform los espera ahí.

4. Desplegar infraestructura con Terraform:

   ```bash
   cd terraform
   terraform init
   terraform apply
   ```

5. Seguir la instalación de OKD:

   ```bash
   openshift-install wait-for bootstrap-complete
   openshift-install wait-for install-complete
   ```

   Acceder a la consola web y al API con el kubeconfig generado.

## Ciclo de laboratorio

Para liberar recursos, destruir todo:

```bash
cd terraform
terraform destroy
```

---

## 7. Resumen mental rápido

- `install-config.yaml` → define el cluster.
- `openshift-install` → genera `.ign`.
- Terraform + libvirt → crean VMs y les enchufan `.ign`.
- Las VMs FCOS → se auto-configuran como bootstrap/master/worker.
- Cuando terminas de jugar → `terraform destroy` y vuelves a K3s.