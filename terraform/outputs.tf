output "vm_ips" {
  value = {
    infra     = var.infra.ip
    bootstrap = var.bootstrap.ip
    master    = var.master.ip
    worker    = var.worker.ip
  }
}
