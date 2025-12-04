# terraform/variables.tf
variable "network_name" { default = "okd-net" }
variable "network_cidr" { default = "10.17.3.0/24" }

variable "ssh_keys" {
  type = list(string)
}

variable "infra" {
  type = object({
    cpus     = number
    memory   = number
    ip       = string
    hostname = string
  })
}

variable "bootstrap" {
  type = object({
    cpus     = number
    memory   = number
    ip       = string
    mac      = string
  })
}

variable "master" {
  type = object({
    cpus     = number
    memory   = number
    ip       = string
    mac      = string
  })
}

variable "worker" {
  type = object({
    cpus     = number
    memory   = number
    ip       = string
    mac      = string
  })
}

variable "coreos_image" {
  description = "Ruta a Fedora CoreOS qcow2"
}

variable "almalinux_image" {
  description = "Ruta a AlmaLinux qcow2"
}
