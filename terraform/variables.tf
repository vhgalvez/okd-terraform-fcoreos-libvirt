
# terraform\variables.tf
# Variables para la configuración de la infraestructura OKD en libvirt

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
# SSH KEYS
#############################################
variable "ssh_keys" {
  description = "Lista de claves públicas SSH autorizadas"
  type        = list(string)
}

#############################################
# NODO INFRA (AlmaLinux)
#############################################
variable "infra" {
  description = "Configuración del nodo infra"
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
    cpus     = number
    memory   = number
    hostname = string
    ip       = string
    mac      = string
  })
}

#############################################
# MASTER 1 (FCOS)
#############################################
variable "master1" {
  description = "Configuración del nodo master 1"
  type = object({
    cpus     = number
    memory   = number
    hostname = string
    ip       = string
    mac      = string
  })
}

#############################################
# MASTER 2 (FCOS - nodo zombi)
#############################################
variable "master2" {
  description = "Configuración del nodo master 2"
  type = object({
    cpus     = number
    memory   = number
    hostname = string
    ip       = string
    mac      = string
  })
}

#############################################
# MASTER 3 (FCOS - nodo zombi)
#############################################
variable "master3" {
  description = "Configuración del nodo master 3"
  type = object({
    cpus     = number
    memory   = number
    hostname = string
    ip       = string
    mac      = string
  })
}

#############################################
# WORKER NODE (FCOS)
#############################################
variable "worker" {
  description = "Configuración del nodo worker"
  type = object({
    cpus     = number
    memory   = number
    hostname = string
    ip       = string
    mac      = string
  })
}

#############################################
# IMÁGENES BASE
#############################################
variable "coreos_image" {
  description = "Ruta o URL del qcow2 de Fedora CoreOS"
  type        = string
}

variable "almalinux_image" {
  description = "Ruta o URL del qcow2 de AlmaLinux"
  type        = string
}

#############################################
# DNS / RED
#############################################
variable "dns1" {
  description = "DNS primario para la red"
  type        = string
}

variable "dns2" {
  description = "DNS secundario para la red"
  type        = string
}

variable "gateway" {
  description = "Gateway de la red libvirt"
  type        = string
}

#############################################
# CLUSTER OKD INFO
#############################################
variable "cluster_domain" {
  description = "Dominio base del clúster OKD (ej. okd.local)"
  type        = string
}

variable "cluster_name" {
  description = "Nombre del cluster OKD (usado en FQDN internos)"
  type        = string
}

#############################################
# IP del nodo infra
#############################################
variable "infra_ip" {
  description = "IP del servidor infra (DNS forwarder)"
  type        = string
}

#############################################
# ZONA HORARIA
#############################################
variable "timezone" {
  description = "Zona horaria del sistema"
  type        = string
  default     = "UTC"
}
