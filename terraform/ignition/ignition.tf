data "local_file" "bootstrap" {
  filename = "${path.module}/../ignition/bootstrap.ign"
}

data "local_file" "master" {
  filename = "${path.module}/../ignition/master.ign"
}

data "local_file" "worker" {
  filename = "${path.module}/../ignition/worker.ign"
}
