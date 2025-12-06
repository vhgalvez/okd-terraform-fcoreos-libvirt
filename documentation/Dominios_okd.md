# ✅ Dominios completos del clúster OKD

**baseDomain = okd.local, name = okd**

Cluster FQDN:  
```
okd.okd.local
```

Esto viene de:

```yaml
name: okd
baseDomain: okd.local
```

Por tanto, toda la infraestructura debe usar `okd.okd.local` como zona DNS interna.

---

## 🟥 1. FQDN principales del API

- **api.okd.okd.local**
  - Endpoint externo de Kubernetes API.
  - Usado por: `oc login`, kubeconfig, accesos externos, workers → API server
  - IP:
    - Durante bootstrap → 10.56.0.11
    - Luego del pivot → 10.56.0.12

- **api-int.okd.okd.local**
  - API interna.
  - Usado por: kubelets, control-plane, servicios internos
  - IP:
    - 10.56.0.11 (bootstrap)
    - 10.56.0.12 (master)

> Ambas deben apuntar SIEMPRE al HAProxy (infra).

---

## 🟧 2. Dominio de aplicaciones

- **\*.apps.okd.okd.local**
  - Wildcard obligatorio.
  - Ejemplos:
    - console-openshift-console.apps.okd.okd.local
    - oauth-openshift.apps.okd.okd.local
    - grafana-openshift-monitoring.apps.okd.okd.local
    - alertmanager-main-openshift-monitoring.apps.okd.okd.local
  - Resuelve al worker con Ingress → 10.56.0.13

---

## 🟩 3. Dominios internos de nodos (Ignition + certificados)

| Nodo      | FQDN                    | IP          |
|-----------|-------------------------|-------------|
| Bootstrap | bootstrap.okd.okd.local | 10.56.0.11  |
| Master    | master.okd.okd.local    | 10.56.0.12  |
| Worker    | worker.okd.okd.local    | 10.56.0.13  |

Estos FQDN deben estar en la zona DNS interna (CoreDNS).

---

## 🟦 4. Dominio DNS interno gestionado por la VM infra

- CoreDNS corre en infra → 10.56.0.10
- FQDN interno del servidor DNS:
  - dns.okd.okd.local → 10.56.0.10
- La zona:
  ```
  $ORIGIN okd.okd.local.
  ```

---

## 📘 Tabla final — Todos los FQDN del clúster

| FQDN / Dominio               | Función                | IP destino      |
|------------------------------|------------------------|-----------------|
| okd.okd.local                | Zona DNS raíz          | —               |
| api.okd.okd.local            | API externa            | 10.56.0.11/12   |
| api-int.okd.okd.local        | API interna            | 10.56.0.11/12   |
| *.apps.okd.okd.local         | Rutas/Ingress          | 10.56.0.13      |
| bootstrap.okd.okd.local      | Bootstrap Ignition     | 10.56.0.11      |
| master.okd.okd.local         | Nodo control-plane     | 10.56.0.12      |
| worker.okd.okd.local         | Nodo worker            | 10.56.0.13      |
| dns.okd.okd.local            | CoreDNS interno        | 10.56.0.10      |

---

## 📌 Dónde deben ir estos dominios exactamente

### 1. `install-config.yaml`

Ya está correcto:

```yaml
baseDomain: okd.local
name: okd
```

No tienes que añadir nada más.

### 2. CoreDNS (`db.okd`)

Debe quedar EXACTO así:

```
$ORIGIN okd.okd.local.
@       IN SOA dns.okd.okd.local. admin.okd.okd.local. (
            2025010101 7200 3600 1209600 3600 )
@       IN NS dns.okd.okd.local.
dns     IN A 10.56.0.10

api         IN A 10.56.0.11
api-int     IN A 10.56.0.11

bootstrap   IN A 10.56.0.11
master      IN A 10.56.0.12
worker      IN A 10.56.0.13

*.apps      IN A 10.56.0.13
```

Después del bootstrap, puedes cambiar:  
api / api-int → 10.56.0.12

### 3. `cloud-init-infra.tpl`

Agregar:

```
dns-search=okd.okd.local
```

### 4. HAProxy

Debe reenviar:

- 6443 → api.okd.okd.local → 10.56.0.11/12
- 22623 → mcs → bootstrap 10.56.0.11
- 80/443 → *.apps.okd.okd.local → worker (10.56.0.13)