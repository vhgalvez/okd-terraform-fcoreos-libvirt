# terraform/variables.tf

# ================================
#  RED
# ================================
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

# ================================
#  SSH KEYS
# ================================
variable "ssh_keys" {
  description = "Lista de claves públicas SSH autorizadas"
  type        = list(string)
}

# ================================
#  INFRA NODE
# ================================
variable "infra" {
  description = "Configuración del nodo infra"
  type = object({
    cpus     = number
    memory   = number
    ip       = string
    hostname = string
  })
}

# ================================
#  BOOTSTRAP NODE
# ================================
variable "bootstrap" {
  description = "Configuración del nodo bootstrap"
  type = object({
    cpus   = number
    memory = number
    ip     = string
    mac    = string
  })
}

# ================================
#  MASTER NODE
# ================================
variable "master" {
  description = "Configuración del nodo master"
  type = object({
    cpus   = number
    memory = number
    ip     = string
    mac    = string
  })
}

# ================================
#  WORKER NODE
# ================================
variable "worker" {
  description = "Configuración del nodo worker"
  type = object({
    cpus   = number
    memory = number
    ip     = string
    mac    = string
  })
}

# ================================
#  IMÁGENES
# ================================
variable "coreos_image" {
  description = "Ruta al archivo qcow2 de Fedora CoreOS"
  type        = string
}

variable "almalinux_image" {
  description = "Ruta al archivo qcow2 de AlmaLinux"
  type        = string
}

# ================================
#  DNS / RED
# ================================
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

variable "cluster_domain" {
  description = "Dominio base del clúster OKD"
  type        = string
}

variable "timezone" {
  description = "Zona horaria del sistema"
  type        = string
  default     = "UTC"
}
