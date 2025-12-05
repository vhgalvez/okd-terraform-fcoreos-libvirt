# okd-terraform-fcoreos-libvirt

Instalación completa de un clúster OKD (OpenShift Origin) sobre Fedora CoreOS, gestionado por Terraform y libvirt/KVM.

Este proyecto está diseñado para **homelabs con recursos limitados**, incluyendo los nodos infra, bootstrap, master y worker.

---

## 1. Arquitectura del laboratorio

El laboratorio utiliza **4 nodos**, balanceados para un servidor doméstico:

| Nodo      | SO             | Rol                              | RAM   | CPU |
|-----------|----------------|-----------------------------------|-------|-----|
| infra     | AlmaLinux 9    | DNS + NTP (CoreDNS + Chrony)      | 512M  | 1   |
| bootstrap | Fedora CoreOS  | Inicializa instalación OKD         | 4 GB  | 2   |
| master    | Fedora CoreOS  | Control Plane OKD                  | 6 GB  | 2   |
| worker    | Fedora CoreOS  | Ejecuta Pods / aplicaciones        | 8 GB  | 2   |

---

## 2. Red del laboratorio

La red libvirt se define así:

- 10.17.3.0/24
  - 10.17.3.10 → infra
  - 10.17.3.21 → bootstrap
  - 10.17.3.22 → master
  - 10.17.3.23 → worker

El nodo `infra` proporciona:

- DNS autoritativo para `*.okd-lab.<dominio>`
- NTP mediante Chrony

---

## 3. Estructura del repositorio

```
okd-terraform-fcoreos-libvirt/
├── DOCUMENTACION.md
├── README.md
├── install-config/
│   └── install-config.yaml
├── terraform/
│   ├── main.tf
│   ├── network.tf
│   ├── vm-infra.tf
│   ├── vm-coreos.tf
│   ├── ignition.tf
│   ├── outputs.tf
│   ├── variables.tf
│   ├── terraform.tfvars
│   ├── files/
│   │   ├── cloud-init-infra.tpl
│   │   ├── coredns.service
│   │   ├── chrony.service
│   │   ├── db.okd
│   │   └── README.md
│   ├── ignition/
│   │   ├── bootstrap.ign
│   │   ├── master.ign
│   │   └── worker.ign
├── deploy.sh
└── destroy.sh
```

---

## 4. Instalación de `openshift-install`

Descargar el instalador OKD:


# Instalador OKD


```bash
cd /tmp
sudo wget https://github.com/okd-project/okd/releases/download/4.21.0-okd-scos.ec.9/openshift-install-linux-4.21.0-okd-scos.ec.9.tar.gz
tar -xvf openshift-install-linux-4.21.0-okd-scos.ec.9.tar.gz
sudo mv openshift-install /opt/bin/
sudo chmod +x /opt/bin/openshift-install
export PATH=$PATH:/opt/bin
echo "export PATH=\$PATH:/opt/bin" >> ~/.bashrc
```

# Cliente (oc + kubectl)

```bash
# OpenShift Client (oc)
sudo curl -L -o /tmp/oc.tar.gz https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz
tar -xzf /tmp/oc.tar.gz -C /tmp
sudo mv /tmp/oc /opt/bin/oc
sudo chmod +x /opt/bin/oc
export PATH=$PATH:/opt/bin
echo "export PATH=\$PATH:/opt/bin" >> ~/.bashrc

```


Verificar instalación:

```bash
openshift-install version
oc version
kubectl version --client

```

---

## 5. Crear `install-config.yaml`

Archivo en: `install-config/install-config.yaml`

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

machineNetwork:
  - cidr: 10.17.3.0/24

platform:
  none: {}

controlPlane:
  name: master
  hyperthreading: Enabled
  replicas: 1

compute:
  - name: worker
    hyperthreading: Enabled
    replicas: 1

pullSecret: "{}"
sshKey: "ssh-rsa AAAA...tu clave..."
```

---

## 6. Generar manifests e Ignition

Desde la carpeta `install-config`:

```bash
cd install-config
openshift-install create manifests --dir=.
openshift-install create ignition-configs --dir=.
```

Esto creará:

- `bootstrap.ign`
- `master.ign`
- `worker.ign`

Copiarlos a Terraform:

```bash
cp bootstrap.ign ../terraform/ignition/
cp master.ign ../terraform/ignition/
cp worker.ign ../terraform/ignition/
```

---

## 7. Configurar Terraform (`terraform.tfvars`)

Ejemplo mínimo:

```hcl
coreos_image = "/var/lib/libvirt/images/fedora-coreos.qcow2"
so_image     = "/var/lib/libvirt/images/AlmaLinux.qcow2"

ssh_keys = [
  "ssh-rsa AAAA... vhgalvez@gmail.com"
]

dns1 = "10.17.3.10"
dns2 = "8.8.8.8"
gateway = "10.17.3.1"
cluster_domain = "cefaslocalserver.com"
```

---

## 8. Crear infraestructura con Terraform

```bash
cd terraform
terraform init
terraform apply -auto-approve
```

Terraform creará:

- red NAT (libvirt)
- nodo infra (cloud-init)
- bootstrap (Ignition)
- master (Ignition)
- worker (Ignition)

---

## 9. Ver progreso de instalación OKD

Usa el installer:

```bash
cd install-config
openshift-install wait-for bootstrap-complete --dir=.
openshift-install wait-for install-complete --dir=.
```

---

## 10. Acceder al clúster

El installer genera:

- `auth/kubeconfig`
- `auth/kubeadmin-password`

Consola OKD Web:

```
https://console-openshift-console.apps.okd-lab.cefaslocalserver.com
```

CLI:

```bash
export KUBECONFIG=auth/kubeconfig
oc get nodes
```

---

## 11. Destruir todo el laboratorio

```bash
cd terraform
terraform destroy -auto-approve
```

---

## 12. Flujo mental resumido

- `install-config.yaml` describe el clúster.
- `openshift-install` genera Ignition.
- Terraform crea VMs y les inyecta Ignition.
- Fedora CoreOS lee Ignition → se convierte en bootstrap/master/worker.
- OKD se instala solo.
- Cuando terminas → destruyes todo con Terraform y vuelves a K3s.

---

## 13. ¿Por qué este proyecto existe?

- ✔ Entender OKD en profundidad
- ✔ Usar Terraform como infraestructura declarativa
- ✔ Aprender Ignition y FCOS
- ✔ Simular un entorno OpenShift corporativo en tu homelab
- ✔ Alternar entre K3s (ligero) y OKD (pesado) cuando quieras


---

sudo nano /etc/sysconfig/nftables.conf

## Aplicar la configuración y habilitar el servicio

1. **Cargar las reglas**:

   ```bash
   sudo nft -f /etc/sysconfig/nftables.conf
   sudo nft list ruleset | sudo tee /etc/sysconfig/nftables.conf
   ```

2. **Habilitar el servicio `nftables` para que se cargue al inicio**:

   ```bash
   sudo systemctl daemon-reexec
   sudo systemctl enable --now nftables
   sudo systemctl restart nftables
   sudo systemctl status nftables
   ```

3. **Validar la configuración**:

   ```bash
   sudo nft list ruleset
   ```

---

## Instalación de herramientas OKD (`oc` + `openshift-install`) en Rocky Linux [Instalación de herramientas OKD ](install_okd.md)


## Configura el `kubeconfig` para acceder al clúster OKD desde la máquina host.

```bash
  sudo chmod +x ./configure_okd_kubeconfig.sh

./configure_okd_kubeconfig.sh

```


sudo chown -R victory:victory /home/victory/okd-terraform-fcoreos-libvirt

cd install-config

openshift-install wait-for bootstrap-complete --log-level=info


cat install-config/install-config.yaml | grep sshKey -n -A2


sudo grep -o "ssh-rsa" ignition/bootstrap.ign | wc -l


verificar si la clave ssh está en el ignition del bootstrap
grep -R "ssh" -n ignition/bootstrap.ign