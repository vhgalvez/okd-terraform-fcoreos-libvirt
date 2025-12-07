# terraform/ignition.tf

# Cargar Ignition generada por openshift-install

resource "libvirt_ignition" "bootstrap" {
  name    = "bootstrap-ignition"
  content = file("${path.module}/../generated/ignition/bootstrap.ign")
}

resource "libvirt_ignition" "master" {
  name    = "master-ignition"
  content = file("${path.module}/../generated/ignition/master.ign")
}

resource "libvirt_ignition" "worker" {
  name    = "worker-ignition"
  content = file("${path.module}/../generated/ignition/worker.ign")
}
