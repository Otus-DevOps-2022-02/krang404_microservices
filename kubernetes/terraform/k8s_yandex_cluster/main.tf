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


resource "yandex_kubernetes_cluster" "k8s_reddit" {
  network_id = var.network_id
  master {
    version = "1.19"

    maintenance_policy {
      auto_upgrade = true
    }

    public_ip = true

    zonal {
      zone      = var.zone
      subnet_id = var.subnet_id
    }
  }
  service_account_id      = data.yandex_iam_service_account.srv_acc.id
  node_service_account_id = data.yandex_iam_service_account.srv_acc.id

  release_channel         = "RAPID"
  network_policy_provider = "CALICO"
}


data "yandex_iam_service_account" "srv_acc" {
  name = "srv-acc"
}

resource "yandex_kubernetes_node_group" "reddit_node_group" {
  cluster_id  = yandex_kubernetes_cluster.k8s_reddit.id
  name        = "reddit-node-group"
  description = "Reddit node group"
  version     = "1.19"


  instance_template {
    platform_id = "standard-v2"

    network_interface {
      nat        = true
      subnet_ids = [var.subnet_id]
    }

    resources {
      memory = 8
      cores  = 4
    }

    boot_disk {
      type = "network-hdd"
      size = 64
    }

    scheduling_policy {
      preemptible = false
    }

    container_runtime {
      type = "containerd"
    }

    metadata = {
      ssh-keys = "ubuntu:${file(var.public_key_path)}"
    }
  }

  scale_policy {
    fixed_scale {
      size = 2
    }
  }

  allocation_policy {
    location {
      zone = "ru-central1-a"
    }
  }
}
