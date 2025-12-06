# 🚀 Flujo completo de instalación y ciclo de vida de OKD 4.x con Terraform + Libvirt

Este documento describe paso a paso el flujo completo para:

- Instalar herramientas de OKD (oc, kubectl, openshift-install)
- Desplegar el clúster con Terraform
- Esperar a que el bootstrap finalice correctamente
- Destruir el nodo bootstrap
- Configurar kubeconfig para usar oc
- (Opcional) Destruir toda la infraestructura
- (Opcional) Desinstalar herramientas de OKD

## 📁 Estructura del proyecto

```
okd-terraform-fcoreos-libvirt/
├── generated/
│   ├── auth/                # kubeconfig + kubeadmin-password (post-ignition)
│   └── ignition/            # *.ign que consume Terraform
├── install-config/
│   └── install-config.yaml  # Configuración base del cluster (NO se borra)
├── scripts/
│   ├── install_okd_tools.sh
│   ├── deploy.sh
│   ├── destroy_bootstrap.sh
│   ├── destroy.sh
│   ├── configure_okd_kubeconfig.sh
│   └── uninstall_okd.sh
└── terraform/
    ├── main.tf
    ├── vm-coreos.tf
    ├── terraform.tfvars
    └── ...
```

> **IMPORTANTE:**  
> `install-config/install-config.yaml` es tu “fuente de verdad”.  
> Nunca se borra. Solo se copia a `generated/` durante el deploy.

---

## 🧰 0. (Opcional) Sincronizar repo con GitHub

Si usas GitHub como origen y quieres que el servidor quede idéntico a `origin/main`:

```bash
cd /home/victory/okd-terraform-fcoreos-libvirt

git fetch --all
git reset --hard origin/main    # ⚠️ Peligroso: borra cambios locales
git clean -fd                   # Limpia ficheros sin trackear (opcional)
git pull                        # Por si hubiera refs nuevas
```

---

## 1️⃣ Instalar herramientas de OKD (oc, kubectl, openshift-install)

Este paso descarga los binarios, verifica hashes y los deja en `/opt/bin`, además de preparar el PATH y symlinks en `/usr/local/bin`.

```bash
cd /home/victory/okd-terraform-fcoreos-libvirt
sudo ./scripts/install_okd_tools.sh
```

Verificación rápida:

```bash
which oc
which kubectl
which openshift-install

oc version --client
openshift-install version
```

---

## 2️⃣ Desplegar el clúster OKD (Ignition + Terraform)

El script `deploy.sh` hace:

- Copia `install-config/install-config.yaml` → `generated/install-config.yaml`
- Ejecuta `openshift-install create ignition-configs --dir=generated/`
- Mueve los *.ign a `generated/ignition/`
- Crea symlink `auth` → `generated/auth`
- Ejecuta `terraform init` + `terraform apply`

Ejecutar:

```bash
cd /home/victory/okd-terraform-fcoreos-libvirt
sudo ./scripts/deploy.sh
```

Puedes ver el progreso de las VMs con:

```bash
sudo virsh list --all
```

Y entrar al bootstrap para ver logs:

```bash
sudo ssh -i /root/.ssh/cluster_k3s/shared/id_rsa_shared_cluster core@10.56.0.11

# Dentro del bootstrap:
journalctl -b -f -u release-image.service -u bootkube.service
```

---

## 3️⃣ Esperar a que el Bootstrap termine correctamente

Una vez que las VMs estén arrancadas, usa openshift-install para esperar al fin de bootstrap.

> Gracias al symlink `auth` → `generated/auth`, basta con ejecutar el comando desde la raíz del proyecto.

```bash
cd /home/victory/okd-terraform-fcoreos-libvirt
openshift-install wait-for bootstrap-complete --log-level=info
```

Si todo va bien verás algo como:

```
INFO Waiting up to 20m0s for the Kubernetes API...
INFO API v1.25.0 up
INFO Waiting up to 30m0s for the bootstrap to complete...
INFO It is now safe to remove the bootstrap resources
```

Ese mensaje “It is now safe to remove the bootstrap resources” es la señal para pasar al siguiente paso.

---

## 4️⃣ Destruir el nodo Bootstrap (manteniendo Master/Worker)

El script `destroy_bootstrap.sh` debe:

- Apagar y eliminar solo la VM bootstrap
- Mantener infra, master, worker intactos

Ejecutar:

```bash
cd /home/victory/okd-terraform-fcoreos-libvirt
sudo ./scripts/destroy_bootstrap.sh
```

Verifica:

```bash
sudo virsh list --all
# Deberías ver infra/master/worker, pero NO bootstrap
```

---

## 5️⃣ Configurar kubeconfig para usar oc (root o tu usuario)

Cuando OKD ya generó el kubeconfig en `generated/auth/kubeconfig`, usa el script:

```bash
cd /home/victory/okd-terraform-fcoreos-libvirt
sudo ./scripts/configure_okd_kubeconfig.sh
```

Este script hace:

- Asegura `/opt/bin` en el PATH de root (y symlinks en `/usr/local/bin`)
- Copia `generated/auth/kubeconfig` → `~/.kube/config` (del usuario que ejecuta el script)
- Ajusta permisos (`chmod 600`)

Verificación:

```bash
# Como root (o el usuario que usaste)
oc whoami
oc get nodes
```

---

## 6️⃣ (Opcional) Destruir TODO el clúster (infraestructura + estado)

Cuando quieras borrar completamente el laboratorio (pero sin tocar las herramientas ni `install-config/install-config.yaml`):

```bash
cd /home/victory/okd-terraform-fcoreos-libvirt
sudo ./scripts/destroy.sh
```

Este script:

- Ejecuta `terraform destroy -auto-approve` en `terraform/`
- Limpia solo la carpeta `generated/` (ignitions, auth, metadata…)
- Elimina los archivos ocultos de openshift-install:
  - `.openshift_install.log*`
  - `.openshift_install_state.json*`
  - `.openshift_install.lock*`
  - `~/.cache/openshift-install`

> **Nota:**  
> La carpeta `install-config/` y tu `install-config.yaml` no se borran.  
> Eso te permite relanzar el deploy sin reescribir la config.

---

## 7️⃣ (Opcional) Desinstalar herramientas de OKD por completo

Si además quieres limpiar los binarios de oc, kubectl, openshift-install y el PATH:

```bash
cd /home/victory/okd-terraform-fcoreos-libvirt
./scripts/uninstall_okd.sh
```

Este script elimina:

- `/opt/bin/oc`
- `/opt/bin/kubectl`
- `/opt/bin/openshift-install`
- Líneas de `/opt/bin` del `~/.bashrc` del usuario que lo ejecuta
- Logs/estado de openshift-install en el directorio actual
- Caché de `~/.cache/openshift-install`
- Carpeta temporal `/tmp/okd-tools`

---

## 🧩 Resumen rápido del flujo normal

Para un ciclo completo de laboratorio:

```bash
cd /home/victory/okd-terraform-fcoreos-libvirt

# 1) Instalar herramientas (solo una vez o cuando actualices)
sudo ./scripts/install_okd_tools.sh

# 2) Desplegar cluster
sudo ./scripts/deploy.sh

# 3) Esperar bootstrap
openshift-install wait-for bootstrap-complete --log-level=info

# 4) Destruir bootstrap
sudo ./scripts/destroy_bootstrap.sh

# 5) Configurar kubeconfig y probar oc
sudo ./scripts/configure_okd_kubeconfig.sh
oc whoami
oc get nodes

# --- Más adelante, cuando quieras limpiar todo ---
sudo ./scripts/destroy.sh          # Destruye cluster
./scripts/uninstall_okd.sh         # (Opcional) Quita herramientas
```