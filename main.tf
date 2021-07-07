terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "3.74.0"
    }
  }
}

provider "google" {
  project     = "schooldevops"
  region      = "europe-west1"
  zone        = "europe-west1-b"
}


//Create instance Build
resource "google_compute_instance" "build" {
  name         = "build"
  machine_type = "f1-micro"
  tags = ["myssh"]
  boot_disk {
    initialize_params {
      image = "ubuntu-2004-focal-v20210623"
    }
  }
  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }
}

//Create instance prod
resource "google_compute_instance" "prod" {
  name         = "prod"
  machine_type = "f1-micro"
  tags = ["myssh","mytomcat"]
  boot_disk {
    initialize_params {
      image = "ubuntu-2004-focal-v20210623"
    }
  }
  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }
  depends_on = [null_resource.build]
}


//Create firewall rule ssh
resource "google_compute_firewall" "myssh" {
  name    = "myssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
    
  }

  source_tags = ["myssh"]
  source_ranges = ["0.0.0.0/0"]
}
//Create firewall rule 8080 tomcat
resource "google_compute_firewall" "mytomcat" {
  name    = "mytomcat"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8080","80","443"]
    
  }

  source_tags = ["mytomcat"]
  source_ranges = ["0.0.0.0/0"]
}


//Ansible config Build
resource "null_resource" "build" {
  triggers = {
    public_ip = google_compute_instance.build.network_interface.0.access_config.0.nat_ip
  }
 provisioner "local-exec" {
    working_dir = "/home/elliot/DevOpsBootcamp/lesson15/"
    command = "ansible-playbook --inventory ${google_compute_instance.build.network_interface.0.access_config.0.nat_ip}, --private-key /home/elliot/.ssh/elliot --user elliot  buildconfig.yaml"
  }
}
//Ansible config Prod
resource "null_resource" "prod" {
  triggers = {
    public_ip = google_compute_instance.prod.network_interface.0.access_config.0.nat_ip
  }
 provisioner "local-exec" {
    working_dir = "/home/elliot/DevOpsBootcamp/lesson15/"
    command = "ansible-playbook --inventory ${google_compute_instance.prod.network_interface.0.access_config.0.nat_ip}, --private-key /home/elliot/.ssh/elliot --user elliot  prodconfig.yaml"
      
  }
}


//Output Extetnal IP
output "Public_IP_address-Build" {
  value = google_compute_instance.build.network_interface.0.access_config.0.nat_ip
}
output "Public_IP_address-Prod" {
  value = google_compute_instance.prod.network_interface.0.access_config.0.nat_ip
}
