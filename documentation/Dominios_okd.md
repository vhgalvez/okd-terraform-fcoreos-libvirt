# 🟦 📘 Dominios oficiales del clúster OKD

**(baseDomain = okd.local, clusterName = okd)**

Tu instalación genera automáticamente el dominio:

```
<name>.<baseDomain> = okd.okd.local
```

Por tanto, el dominio raíz del clúster es:

```
okd.okd.local
```

---

## 🟥 1. Dominios de la API del clúster

- **api.okd.okd.local**
  - **Función:** Punto de entrada principal para:
    - `oc login`
    - Kubernetes API Server (port 6443)
    - Comunicación del bootstrap/master hacia el API server
    - kubeconfig del clúster
  - **Resuelto en tu homelab a:**
    - 10.56.0.11 (bootstrap) durante instalación
    - 10.56.0.12 (master) después

- **api-int.okd.okd.local**
  - **Función:** API interna, usada por:
    - kube-apiserver del master hacia sí mismo
    - kubelets
    - control plane interno
  - **Resuelto igual que el API externo:**
    - 10.56.0.11 bootstrap
    - 10.56.0.12 master

---

## 🟧 2. Dominio de aplicaciones

- **\*.apps.okd.okd.local**
  - **Función:** Wildcard necesario para todas las rutas del Ingress de OpenShift:
    - Ejemplos:
      - console-openshift-console.apps.okd.okd.local
      - oauth-openshift.apps.okd.okd.local
      - grafana-openshift-monitoring.apps.okd.okd.local
      - alertmanager-main-openshift-monitoring.apps.okd.okd.local
  - **Resuelto a:** 10.56.0.13 (worker con ingress)

---

## 🟩 3. Dominios internos del bootstrap y nodos

- **bootstrap.okd.okd.local**
- **master.okd.okd.local**
- **worker.okd.okd.local**

  - **Función:** DNS A records requeridos para:
    - Ignition de másters (master.ign)
    - kubelet bootstrap
    - certificados del cluster
    - planeamiento de red interna
  - **Resueltos a:**
    - bootstrap → 10.56.0.11  
    - master    → 10.56.0.12  
    - worker    → 10.56.0.13  

---

## 🟦 4. Dominio DNS interno gestionado por CoreDNS

- **dns.okd.okd.local**
  - **Función:** Servidor DNS interno del cluster:
    - Resuelve api/api-int
    - Resuelve bootstrap/master/worker
    - Zona interna para OKD
    - Forwarding hacia internet
  - Este es el CoreDNS que configuramos en la VM infra:
    - infra.okd.local → 10.56.0.10

---

## 📘 LISTA COMPLETA EN TABLA PARA DOCUMENTACIÓN

| Dominio/FQDN                | Descripción                                   | IP destino       |
|-----------------------------|-----------------------------------------------|------------------|
| okd.okd.local               | Dominio raíz del clúster                      | —                |
| api.okd.okd.local           | API Server externa (oc login)                 | 10.56.0.11/12    |
| api-int.okd.okd.local       | API Server interna (kubelets, control plane)  | 10.56.0.11/12    |
| *.apps.okd.okd.local        | Wildcard para aplicaciones e Ingress          | 10.56.0.13       |
| bootstrap.okd.okd.local     | Nodo bootstrap                                | 10.56.0.11       |
| master.okd.okd.local        | Máster                                        | 10.56.0.12       |
| worker.okd.okd.local        | Worker                                        | 10.56.0.13       |
| dns.okd.okd.local           | Servidor CoreDNS interno                      | 10.56.0.10       |

---

## 📌 ¿Dónde se usan estos dominios?

- En `install-config.yaml`
  ```
  baseDomain: okd.local
  name: okd
  ```
- En CoreDNS (`db.okd`)
  ```
  $ORIGIN okd.okd.local.
  ```
- En HAProxy
  - api / mcs / ingress
- En terraform → `cloud-init-infra.tpl`
  ```
  dns-search=okd.okd.local
  ```