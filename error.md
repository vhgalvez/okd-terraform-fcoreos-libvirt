# 📌 OKD en servidores antiguos sin AVX (HP ProLiant DL380 G7)

Tu servidor usa CPUs **Intel Xeon X5650 (Westmere, 2010)**. Estas CPUs:

- ❌ No soportan AVX / AVX2
- ❌ No cumplen el perfil moderno x86-64-v2 / x86-64-v3
- ✔ Soportan solo el perfil clásico x86-64 “viejo”

Desde las versiones recientes, tanto SCOS 9 como Fedora CoreOS 40+ vienen compilados para x86-64-v2/v3, lo que provoca el error:

```
Fatal glibc error: CPU does not support x86-64-v3
```

## ¿Qué significa esto?

- ❌ OKD 4.18, 4.19 y posteriores **NO** son utilizables en tu DL380 G7
- ❌ SCOS 9 + OKD 4.19 **NO** solucionan el problema, lo empeoran
- ✅ Hay que usar una versión de OKD basada en un sistema operativo más antiguo, compatible con CPUs sin AVX

## ✅ Versión recomendada para tu hardware

La combinación realista para un DL380 G7 es:

- 🟢 **OKD 4.12**
- 🟢 **Fedora CoreOS (FCOS) 3x** (por ejemplo, FCOS 38 estable)

Estas versiones:

- Están basadas en una userland más antigua (similar a RHEL8/Fedora 3x)
- No exigen x86-64-v2/v3
- No requieren AVX / AVX2
- Evitan el error `Fatal glibc error: CPU does not support x86-64-v3`

---

## 1️⃣ Descargar herramientas de OKD 4.12 (oc + installer)

💡 Siempre usa URLs y hashes de la página oficial de OKD 4.12 para asegurarte de que no cambian.

Ejemplo de variables en tu script `install_okd_tools.sh`:

```bash
# Cliente (oc + kubectl)
OKD_CLIENT_URL="https://github.com/okd-project/okd/releases/download/4.12.0-0.okd-2023-01-21-042244/openshift-client-linux-4.12.0-0.okd-2023-01-21-042244.tar.gz"

# Installer
OKD_INSTALLER_URL="https://github.com/okd-project/okd/releases/download/4.12.0-0.okd-2023-01-21-042244/openshift-install-linux-4.12.0-0.okd-2023-01-21-042244.tar.gz"
```

Luego en el script:

```bash
BIN_DIR="/opt/bin"

sudo mkdir -p "$BIN_DIR"

# Descargar y extraer cliente
cd /tmp
wget -q "$OKD_CLIENT_URL" -O openshift-client-linux.tar.gz
tar -xzf openshift-client-linux.tar.gz oc kubectl
sudo mv -f oc kubectl "$BIN_DIR/"
sudo chmod +x "$BIN_DIR/oc" "$BIN_DIR/kubectl"

# Descargar y extraer installer
wget -q "$OKD_INSTALLER_URL" -O openshift-install-linux.tar.gz
tar -xzf openshift-install-linux.tar.gz openshift-install
sudo mv -f openshift-install "$BIN_DIR/"
sudo chmod +x "$BIN_DIR/openshift-install"
```

Y aseguras el PATH:

```bash
if ! grep -q "export PATH=/opt/bin:\$PATH" "$HOME/.bashrc"; then
  echo 'export PATH=/opt/bin:$PATH' >> "$HOME/.bashrc"
fi
export PATH=/opt/bin:$PATH
```

---

## 2️⃣ Descargar la imagen Fedora CoreOS compatible

Descarga una imagen Fedora CoreOS estable de la rama 3x (por ejemplo, FCOS 38) en QEMU qcow2 y cópiala a tu directorio de imágenes de libvirt:

```bash
cd /var/lib/libvirt/images/

# Ejemplo (ajusta la URL a la release estable que elijas de FCOS 3x)
sudo wget https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/38.20230918.3.0/x86_64/fedora-coreos-38.20230918.3.0-qemu.x86_64.qcow2.xz
xz -d fedora-coreos-38.20230918.3.0-qemu.x86_64.qcow2.xz
```

Resultado esperado:

```
/var/lib/libvirt/images/fedora-coreos-38.20230806.3.0-qemu.x86_64.qcow2
```

---

## 3️⃣ Ajustar Terraform para usar FCOS 38 (no SCOS 9)

En tu `terraform.tfvars` o donde definas la ruta de la imagen:

❌ **Antes** (incorrecto, FCOS 41 / SCOS 9 / versiones nuevas):

```hcl
coreos_image = "/var/lib/libvirt/images/fedora-coreos-41.20250315.3.0-qemu.x86_64.qcow2"
# o
coreos_image = "/var/lib/libvirt/images/scos-9.0.20250515-0-metal.x86_64.raw"
```

✅ **Después** (correcto para tu DL380 G7):

```hcl
coreos_image = "/var/lib/libvirt/images/fedora-coreos-38.20230806.3.0-qemu.x86_64.qcow2"
```

Terraform soporta tanto qcow2 como raw, pero en tu caso lo más cómodo es mantener qcow2 QEMU como en el repo original.

---

## 4️⃣ Generar Ignition con el installer de OKD 4.12

Con `openshift-install` ya en `/opt/bin` y el PATH configurado:

```bash
mkdir -p install-config

# (Debes tener tu install-config.yaml ya creado en install-config/)
openshift-install create ignition-configs --dir=install-config
```

Esto genera:

- `install-config/bootstrap.ign`
- `install-config/master.ign`
- `install-config/worker.ign`

Luego tu `deploy.sh` copia esos archivos a la carpeta `ignition/` y Terraform los usa para cada VM:

```bash
cp install-config/*.ign ignition/
```

Ignition v3 funciona igual con FCOS 38 + OKD 4.12.

---

## 5️⃣ Flujo completo simplificado

1. Instalar herramientas OKD 4.12 (oc, kubectl, openshift-install)
2. Descargar imagen Fedora CoreOS 38 compatible y apuntarla en Terraform
3. Generar Ignition con `openshift-install create ignition-configs`
4. Copiar `.ign` a `ignition/`
5. Ejecutar:

```bash
terraform -chdir=terraform init
terraform -chdir=terraform apply -var-file="terraform.tfvars" -auto-approve
```

6. Ver logs en el bootstrap:

```bash
ssh core@<IP_BOOTSTRAP>   # usando tu llave
journalctl -b -f -u release-image.service -u bootkube.service
```

---

En esta combinación:

- ✔ No aparece `Fatal glibc error: CPU does not support x86-64-v3`
- ✔ `node-image-pull.service` y `bootkube.service` pueden arrancar
- ✔ El bootstrap puede completar su trabajo y el clúster sigue la instalación

---

## 6️⃣ Resumen clave (lo que estaba mal y ya NO debes usar)

❌ **NO usar documentación/flujo que diga:**

- “OKD 4.19 + SCOS es la solución para CPUs sin AVX”
- “Tu DL380 G7 solo funciona con SCOS”
- “SCOS 9 arregla el error de glibc”

Porque en la práctica:

- SCOS 9 también está compilado para x86-64-v2/v3
- Sigue dando errores de CPU (`Fatal glibc error`) en tu Xeon X5650
- OKD 4.18 / 4.19 no son viables en este hardware

✅ **Lo correcto para tu servidor:**

- OKD 4.12 + Fedora CoreOS 3x (ej. FCOS 38) + Terraform + libvirt