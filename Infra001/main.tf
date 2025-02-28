# Configure the Google Cloud provider
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
    ansible = {
      version = "~> 1.3.0"
      source  = "ansible/ansible"
    }
  }
}

provider "google" {
  credentials = file("./secrets/credentials.json")
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# VM configuration variables
locals {
  vm_configs = [
    {
      name = "k3s-vm-1-m"
      machine_type = "e2-medium"  # 2 vCPU, 4GB memory
      tags = ["k3s", "master"]
    },
    {
      name = "k3s-vm-2-m"
      machine_type = "e2-medium"
      tags = ["k3s", "master"]
    },
    {
      name = "k3s-vm-3-m"
      machine_type = "e2-medium"
      tags = ["k3s", "master"]
    },
    {
      name = "k3s-vm-4-w"
      machine_type = "e2-medium"  
      tags = ["k3s", "worker"]
    },
    {
      name = "k3s-vm-5-w"
      machine_type = "e2-medium"
      tags = ["k3s", "worker"]
    }
  ]
}

# Create VMs
resource "google_compute_instance" "vms" {
  count        = length(local.vm_configs)
  name         = local.vm_configs[count.index].name
  machine_type = local.vm_configs[count.index].machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"  # Use Ubuntu 20.04 LTS
      size  = 20  # GB
      type  = "pd-standard"  # Makes the disk persistent
    }
  }

  network_interface {
    network = "default"
    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    ssh-keys = "user:${file("~/.ssh/id_rsa.pub")}"
  }

  tags = local.vm_configs[count.index].tags

  #metadata_startup_script = <<-EOF
  #            #!/bin/bash
  #            # Add any startup configuration here
  #            EOF

}

# allow SSH with ufw
resource "google_compute_firewall" "allow-ssh" {
  name    = "allow-ssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
    ports    = ["22",
                "80",
                "8080",
                "6444",
                "6443",
                "32002"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["k3s"]
}

output "master_nodes" {
  value = {
    for instance in google_compute_instance.vms :
    instance.name => {
      internal_ip = instance.network_interface[0].network_ip
      external_ip = instance.network_interface[0].access_config[0].nat_ip
    }
    if can(regex("-m$", instance.name))
  }
  description = "IPs of master nodes"
}

output "worker_nodes" {
  value = {
    for instance in google_compute_instance.vms :
    instance.name => {
      internal_ip = instance.network_interface[0].network_ip
      external_ip = instance.network_interface[0].access_config[0].nat_ip
    }
    if can(regex("-w$", instance.name))
  }
  description = "IPs of worker nodes"
}
