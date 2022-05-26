terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.35"
    }
  }
  required_version = ">= 1.00"
}

provider "yandex" {
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
  service_account_key_file = var.service_account_key_file
}

resource "yandex_compute_instance" "docker" {
  count                     = var.instance_count
  name                      = "docker-host-${count.index}"
  allow_stopping_for_update = true
  labels = {
    tags = "docker-host"
  }
  resources {
    core_fraction = 5
    cores         = 2
    memory        = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = 15
    }
  }

  network_interface {
    # Указан id подсети default-ru-central1-a
    subnet_id = var.subnet_id
    nat       = true
  }

  scheduling_policy {
    preemptible = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
}

resource "yandex_lb_target_group" "ya_target" {
  name      = "yatarget"
  folder_id = var.folder_id
  region_id = "ru-central1"

  dynamic "target" {
    for_each = yandex_compute_instance.docker.*.network_interface.0.ip_address

    content {
      subnet_id = var.subnet_id
      address   = target.value
    }
  }
}

resource "yandex_lb_network_load_balancer" "lb_reddit" {
  name      = "redditloadbalancer"
  folder_id = var.folder_id

  listener {
    name        = "listenreddit"
    port        = "80"
    target_port = "9292"
    external_address_spec {
      ip_version = "ipv4"
    }
  }
  attached_target_group {
    target_group_id = yandex_lb_target_group.ya_target.id

    healthcheck {
      name = "http"
      tcp_options {
        port = "9292"
      }
    }
  }
}
