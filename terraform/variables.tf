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
  type = object({
    cpus     = number
    memory   = number
    ip       = string
    hostname = string
  })
}

# ================================
#  BOOTSTRAP
# ================================
variable "bootstrap" {
  type = object({
    cpus   = number
    memory = number
    ip     = string
    mac    = string
  })
}

# ================================
#  MASTER
# ================================
variable "master" {
  type = object({
    cpus   = number
    memory = number
    ip     = string
    mac    = string
  })
}

# ================================
#  WORKER
# ================================
variable "worker" {
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