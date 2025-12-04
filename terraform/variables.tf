# terraform/variables.tf

variable "network_name" {
  description = "Nombre de la red libvirt para OKD"
  type        = string
  default     = "okd-net"
}

variable "network_cidr" {
  description = "CIDR de la red libvirt"
  type        = string
  default     = "10.17.3.0/24"
}

variable "ssh_keys" {
  description = "Lista de claves públicas SSH autorizadas"
  type        = list(string)
}

variable "infra" {
  description = "Configuración del nodo infra"
  type = object({
    cpus     = number
    memory   = number
    ip       = string
    hostname = string
  })
}

variable "bootstrap" {
  description = "Configuración del nodo bootstrap"
  type = object({
    cpus   = number
    memory = number
    ip     = string
    mac    = string
  })
}

variable "master" {
  description = "Configuración del nodo master"
  type = object({
    cpus   = number
    memory = number
    ip     = string
    mac    = string
  })
}

variable "worker" {
  description = "Configuración del nodo worker"
  type = object({
    cpus   = number
    memory = number
    ip     = string
    mac    = string
  })
}

variable "coreos_image" {
  description = "Ruta al qcow2 de Fedora CoreOS"
  type        = string
}

variable "almalinux_image" {
  description = "Ruta al qcow2 de AlmaLinux"
  type        = string
}

variable "dns1" {
  description = "Servidor DNS primario para el nodo infra"
  type        = string
}

variable "dns2" {
  description = "Servidor DNS secundario para el nodo infra"
  type        = string
}

variable "gateway" {
  description = "Gateway de la red libvirt"
  type        = string
}

variable "cluster_domain" {
  description = "Dominio base del laboratorio OKD"
  type        = string
}

variable "timezone" {
  description = "Zona horaria para el nodo infra"
  type        = string
  default     = "UTC"
}
