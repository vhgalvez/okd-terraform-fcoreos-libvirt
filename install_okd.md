# Guía rápida: Instalación de herramientas OKD (`oc` + `openshift-install`)

Este documento explica cómo instalar los binarios necesarios para trabajar con OKD:

- **OpenShift Client (`oc`)**
- **OKD Installer (`openshift-install`)**

Ambos se instalarán en `/opt/bin` para mantener el sistema ordenado y limpio.

---

## 1. Instalar dependencias básicas

Ejecuta en tu servidor Rocky/Alma/RHEL:

```bash
sudo dnf install -y wget curl tar
```

---

## 2. Dar permisos al instalador

Si ya tienes el script `install_okd_tools.sh` en tu repositorio, ponle permisos:

```bash
chmod +x install_okd_tools.sh
```

---

## 3. Ejecutar el instalador

```bash
./install_okd_tools.sh
```

Durante la instalación verás mensajes como:

- Descargando oc
- Descomprimiendo binarios
- Moviendo ejecutables a /opt/bin
- Verificando versiones instaladas

---

## 4. Verificar instalación

✔️ Verificar `oc`:

```bash
oc version
```

Salida esperada:

```
Client Version: 4.x.x
```

✔️ Verificar `openshift-install`:

```bash
openshift-install version
```

Salida esperada:

```
openshift-install 4.21.0-okd-scos.ec.9
```

---

## 5. Añadir los binarios al PATH (si hace falta)

Normalmente el instalador ya lo hace automáticamente.  
Si deseas forzarlo manualmente:

```bash
echo 'export PATH=$PATH:/opt/bin' >> ~/.bashrc
source ~/.bashrc
```

---

## 6. Actualizar OKD en el futuro

Si quieres actualizar a una nueva versión:

```bash
sudo rm /opt/bin/openshift-install
sudo rm /opt/bin/oc
./install_okd_tools.sh
```

El script volverá a descargar las últimas versiones configuradas en él.

---

## 7. Desinstalar herramientas

Si deseas eliminar todo:

```bash
sudo rm -f /opt/bin/oc
sudo rm -f /opt/bin/openshift-install
sed -i '/\/opt\/bin/d' ~/.bashrc
```

Esto elimina los binarios y limpia el PATH.