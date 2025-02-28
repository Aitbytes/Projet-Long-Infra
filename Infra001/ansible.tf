# Ansible resources
resource "ansible_host" "master_nodes" {
  for_each = {
    for instance in google_compute_instance.vms :
    instance.name => {
      internal_ip = instance.network_interface[0].network_ip
      external_ip = instance.network_interface[0].access_config[0].nat_ip
    }
    if can(regex("-m$", instance.name))
  }

  name   = each.key
  groups = ["master", "k3s_cluster"]
  variables = {
    ansible_host = each.value.external_ip  # or internal_ip
  }
}

resource "ansible_host" "worker_nodes" {
  for_each = {
    for instance in google_compute_instance.vms :
    instance.name => {
      internal_ip = instance.network_interface[0].network_ip
      external_ip = instance.network_interface[0].access_config[0].nat_ip
    }
    if can(regex("-w$", instance.name))
  }

  name   = each.key
  groups = ["worker", "k3s_cluster"]
  variables = {
    ansible_host = each.value.external_ip  # or internal_ip
  }
}

resource "ansible_group" "master" {
  name     = "master"
  children = ["k3s_cluster"]
}

resource "ansible_group" "worker" {
  name     = "worker"
  children = ["k3s_cluster"]
}

resource "ansible_group" "k3s_cluster" {
  name = "k3s_cluster"
}

resource "local_file" "ansible_inventory" {
  content = templatefile("inventory.tftpl", {
    master_nodes = {
      for instance in google_compute_instance.vms :
      instance.name => {
        internal_ip = instance.network_interface[0].network_ip
        external_ip = instance.network_interface[0].access_config[0].nat_ip
      }
      if can(regex("-m$", instance.name))
    }
    worker_nodes = {
      for instance in google_compute_instance.vms :
      instance.name => {
        internal_ip = instance.network_interface[0].network_ip
        external_ip = instance.network_interface[0].access_config[0].nat_ip
      }
      if can(regex("-w$", instance.name))
    }
  })
  filename = "inventory.yml"
}
