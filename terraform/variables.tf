# terraform/variables.tf
#############################################
# RED
#############################################
variable "network_name" {
  description = "Nombre de la red libvirt para OKD"
  type        = string
  default     = "okd-net"
}

variable "network_cidr" {
  description = "CIDR de la red libvirt"
  type        = string
  default     = "10.56.0.0/24"
}

#############################################
# NODO INFRA (AlmaLinux)
#############################################
variable "infra" {
  description = "Configuración del nodo infra (DNS, NTP, LB)"
  type = object({
    cpus     = number
    memory   = number
    ip       = string
    hostname = string
    mac      = string
  })
}

#############################################
# BOOTSTRAP NODE (FCOS)
#############################################
variable "bootstrap" {
  description = "Configuración del nodo bootstrap"
  type = object({
    cpus   = number
    memory = number
    ip     = string
    mac    = string
  })
}

#############################################
# MASTER NODE (FCOS)
#############################################
variable "master" {
  description = "Configuración del nodo master"
  type = object({
    cpus   = number
    memory = number
    ip     = string
    mac    = string
  })
}

#############################################
# WORKER NODE (FCOS)
#############################################
variable "worker" {
  description = "Configuración del nodo worker"
  type = object({
    cpus   = number
    memory = number
    ip     = string
    mac    = string
  })
}

#############################################
# IMÁGENES BASE
#############################################
variable "coreos_image" {
  description = "URL o ruta local al QCOW2 de Fedora CoreOS"
  type        = string
}

variable "almalinux_image" {
  description = "Ruta al QCOW2 de AlmaLinux para nodo infra"
  type        = string
}

#############################################
# SSH KEYS
#############################################
variable "ssh_keys" {
  description = "Claves SSH públicas autorizadas para nodos FCOS"
  type        = list(string)
}

#############################################
# CLUSTER INFO
#############################################
variable "cluster_domain" {
  description = "Dominio del cluster OKD"
  type        = string
  default     = "local"
}

variable "cluster_name" {
  description = "Nombre del cluster OKD"
  type        = string
  default     = "okd"
}

#############################################
# INFRA IP PARA DNS FORWARD
#############################################
variable "infra_ip" {
  description = "IP del nodo infra (usado como DNS forwarder)"
  type        = string
}

#############################################
# ZONA HORARIA
#############################################
variable "timezone" {
  description = "Zona horaria para los nodos"
  type        = string
  default     = "UTC"
}


#############################################
# DNS / GATEWAY para nodo infra
#############################################
variable "dns1" {
  description = "DNS primario"
  type        = string
}

variable "dns2" {
  description = "DNS secundario"
  type        = string
}

variable "gateway" {
  description = "Gateway predeterminado del nodo infra"
  type        = string
}
