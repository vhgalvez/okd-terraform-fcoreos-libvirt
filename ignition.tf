# NOTA IMPORTANTE:
# Los archivos bootstrap.ign, master.ign y worker.ign
# deben existir en ../ignition, generados por openshift-install
# (NO los escribes a mano, los saca OKD).

resource "libvirt_ignition" "bootstrap" {
  name    = "bootstrap.ign"
  pool    = libvirt_pool.okd.name
  content = file("${path.module}/../ignition/bootstrap.ign")
}

resource "libvirt_ignition" "master" {
  name    = "master.ign"
  pool    = libvirt_pool.okd.name
  content = file("${path.module}/../ignition/master.ign")
}

resource "libvirt_ignition" "worker" {
  name    = "worker.ign"
  pool    = libvirt_pool.okd.name
  content = file("${path.module}/../ignition/worker.ign")
}
