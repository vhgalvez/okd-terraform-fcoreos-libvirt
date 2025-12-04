# Ignition configs para OKD

Estos archivos **NO** se escriben a mano.

Se generan con `openshift-install` a partir de `install-config/install-config.yaml`:

```bash
cd install-config
openshift-install create ignition-configs --dir=.
```

Esto generará:

- `bootstrap.ign`
- `master.ign`
- `worker.ign`

---

## 🟦 12. `install-config/install-config.yaml` (plantilla base)

👉 **Esto es solo un ejemplo**, ajusta dominios, red, pullSecret, sshKey, etc.

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

platform:
  none: {}

controlPlane:
  hyperthreading: Enabled
  name: master
  replicas: 1

compute:
  - hyperthreading: Enabled
    name: worker
    replicas: 1

pullSecret: "<TU_PULL_SECRET_JSON>"
sshKey: "ssh-rsa AAAA... tu clave ... vhgalvez@gmail.com"
```

Luego:

```bash
cd install-config
openshift-install create ignition-configs --dir=.
# Copia los .ign a ../ignition si hace falta
```

---

## 13. butane/ (opcional, si quieres jugar con FCOS fuera de OKD)

Por ejemplo, `butane/bootstrap.bu`:

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

Y un Makefile:

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

> **Nota:** Para OKD puro, lo normal es usar los `.ign` que genera `openshift-install`, no Butane manual.

---

## 14. README principal (`README.md` en la raíz)

Mini-esqueleto:

# okd-terraform-fcoreos-libvirt

Laboratorio de OKD (OpenShift Origin) sobre Fedora CoreOS y libvirt/KVM, orquestado con Terraform. Diseñado para homelab con recursos limitados:

- 1 nodo infra (AlmaLinux: DNS + NTP)
- 1 nodo bootstrap (FCOS)
- 1 master (FCOS)
- 1 worker (FCOS)

## Flujo resumido

1. Preparar imágenes:

   - Fedora CoreOS qcow2
   - AlmaLinux GenericCloud qcow2

2. Editar `terraform/terraform.tfvars` con:

   - rutas de imágenes
   - IPs / MACs
   - clave SSH

3. Crear `install-config/install-config.yaml` y generar Ignitions:

   ```bash
   cd install-config
   openshift-install create ignition-configs --dir=.
   ```

4. Copiar (o apuntar) los `.ign` a `ignition/`:

   - `ignition/bootstrap.ign`
   - `ignition/master.ign`
   - `ignition/worker.ign`

5. Desplegar infraestructura:

   ```bash
   cd terraform
   terraform init
   terraform apply
   ```

Seguir la instalación de OKD (bootstrap, wait-for install-complete, etc.).

---

Si quieres, en el siguiente mensaje puedo:

- Ajustar los tamaños de RAM/CPU finamente a tu servidor (para no matar nada).
- Escribir un `docs/install-steps.md` con todos los comandos desde cero (incluyendo cuándo destruir K3s y cuándo levantar OKD).
  ::contentReference[oaicite:0]{index=0}



🧠 Notas importantes sobre este archivo
✔ 1. platform: none

Esto es obligatorio cuando NO usas AWS, Azure, GCP, vSphere, etc.

✔ 2. replicas: 1

OKD oficialmente pide 3 masters, pero para laboratorio funciona perfectamente con 1.

✔ 3. machineCIDR: 10.17.3.0/24

Esta es tu red libvirt.

✔ 4. pullSecret

Debes usar una válida:

Si usas OKD (comunidad) → pon una cadena vacía:

pullSecret: "{}"


Si usas OpenShift Installer (Red Hat) → debes poner una real.

✔ 5. Después de crear este archivo:

Ejecutas:

openshift-install create manifests --dir=install-config
openshift-install create ignition-configs --dir=install-config


Y tendrás:

bootstrap.ign

master.ign

worker.ign

Terraform los inyecta a cada VM CoreOS.