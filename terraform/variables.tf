<<<<<<< HEAD
# ================================
#  RED
# ================================
variable "network_name" {
  type    = string
  default = "okd-net"
}

variable "network_cidr" {
  type    = string
  default = "10.17.3.0/24"
}

# ================================
#  SSH KEYS
# ================================
variable "ssh_keys" {
  type = list(string)
}

# ================================
#  INFRA
# ================================
variable "infra" {
=======
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
>>>>>>> 0d3d0830d724ed640ce167dc4bb0d1f511a4cd88
  type = object({
    cpus     = number
    memory   = number
    ip       = string
    hostname = string
  })
}

<<<<<<< HEAD
# ================================
#  BOOTSTRAP
# ================================
variable "bootstrap" {
=======
variable "bootstrap" {
  description = "Configuración del nodo bootstrap"
>>>>>>> 0d3d0830d724ed640ce167dc4bb0d1f511a4cd88
  type = object({
    cpus   = number
    memory = number
    ip     = string
    mac    = string
  })
}

<<<<<<< HEAD
# ================================
#  MASTER
# ================================
variable "master" {
=======
variable "master" {
  description = "Configuración del nodo master"
>>>>>>> 0d3d0830d724ed640ce167dc4bb0d1f511a4cd88
  type = object({
    cpus   = number
    memory = number
    ip     = string
    mac    = string
  })
}

<<<<<<< HEAD
# ================================
#  WORKER
# ================================
variable "worker" {
=======
variable "worker" {
  description = "Configuración del nodo worker"
>>>>>>> 0d3d0830d724ed640ce167dc4bb0d1f511a4cd88
  type = object({
    cpus   = number
    memory = number
    ip     = string
    mac    = string
  })
}

<<<<<<< HEAD
# ================================
#  IMÁGENES
# ================================
variable "coreos_image" {
  type        = string
  description = "Ruta a Fedora CoreOS qcow2"
}

variable "almalinux_image" {
  type        = string
  description = "Ruta a AlmaLinux qcow2"
}

# ================================
#  DNS / RED
# ================================
variable "dns1" {
  type = string
}

variable "dns2" {
  type = string
}

variable "gateway" {
  type = string
}

variable "cluster_domain" {
  type = string
}

variable "timezone" {
  type = string
}
=======
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
>>>>>>> 0d3d0830d724ed640ce167dc4bb0d1f511a4cd88
