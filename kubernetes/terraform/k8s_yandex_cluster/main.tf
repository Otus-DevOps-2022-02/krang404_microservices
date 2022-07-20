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

resource "yandex_vpc_network" "cluster_network" {
  name = "k8s-vpc"
}

# Создание подсети
resource "yandex_vpc_subnet" "task_subnet_a" {
  name           = "task-subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.cluster_network.id
  v4_cidr_blocks = ["192.168.1.0/24"]
}

resource "yandex_compute_disk" "k8s" {
  name = "k8s"
  type = "network-hdd"
  zone = "ru-central1-a"
  size = 4

  labels = {
    device_name = "disk-data"
  }
}

resource "yandex_kubernetes_cluster" "k8s_reddit" {
  network_id = yandex_vpc_network.cluster_network.id
  master {
    version = "1.19"

    maintenance_policy {
      auto_upgrade = true
    }

    public_ip = true
    security_group_ids = [
      yandex_vpc_security_group.k8s_main_sg.id,
      yandex_vpc_security_group.k8s_master_whitelist.id
    ]

    zonal {
      zone      = var.zone
      subnet_id = yandex_vpc_subnet.task_subnet_a.id
    }
  }

  cluster_ipv4_range = "10.141.0.0/16"
  service_ipv4_range = "172.18.0.0/16"

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
      subnet_ids = [yandex_vpc_subnet.task_subnet_a.id]
      security_group_ids = [
        yandex_vpc_security_group.k8s_main_sg.id,
        yandex_vpc_security_group.k8s_nodes_ssh_access.id,
        yandex_vpc_security_group.k8s_public_services.id
      ]
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

#------------Создание SG

resource "yandex_vpc_security_group" "k8s_main_sg" {
  name        = "k8s-main-sg"
  description = "Правила группы обеспечивают базовую работоспособность кластера. Примените ее к кластеру и группам узлов."
  network_id  = yandex_vpc_network.cluster_network.id
  ingress {
    protocol    = "TCP"
    description = "Правило разрешает проверки доступности с диапазона адресов балансировщика нагрузки. Нужно для работы отказоустойчивого кластера и сервисов балансировщика."
    # Используем рекомендованный в документации способ разрешения доступа к балансировщикам
    predefined_target = "loadbalancer_healthchecks"
    from_port         = 0
    to_port           = 65535
  }
  ingress {
    protocol          = "ANY"
    description       = "Правило разрешает взаимодействие мастер-узел и узел-узел внутри группы безопасности."
    predefined_target = "self_security_group"
    # Расширяем диапазон портов до максимума для взаимодействия между узлами
    from_port = 0
    to_port   = 65535
  }
  ingress {
    protocol    = "ANY"
    description = "Правило разрешает взаимодействие под-под и сервис-сервис. Укажите подсети вашего кластера и сервисов."
    # Записываем диапазоны подсетей, созданных вместе с кластером
    v4_cidr_blocks = ["10.141.0.0/16", "172.18.0.0/16"]
    from_port      = 0
    to_port        = 65535
  }
  ingress {
    protocol    = "ICMP"
    description = "Правило разрешает отладочные ICMP-пакеты из внутренних подсетей."
    # Добавляем все диапазоны из RFC 1918
    v4_cidr_blocks = ["172.16.0.0/12", "10.0.0.0/8", "192.168.0.0/16"]
  }
  egress {
    protocol       = "ANY"
    description    = "Правило разрешает весь исходящий трафик. Узлы могут связаться с Yandex Container Registry, Object Storage, Docker Hub и т. д."
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

resource "yandex_vpc_security_group" "k8s_public_services" {
  name        = "k8s-public-services"
  description = "Правила группы разрешают подключение к сервисам из интернета. Примените правила только для групп узлов."
  network_id  = yandex_vpc_network.cluster_network.id

  ingress {
    protocol       = "TCP"
    description    = "Правило разрешает входящий трафик из интернета на диапазон портов NodePort. Добавьте или измените порты на нужные вам."
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 30000
    to_port        = 32767
  }
}

resource "yandex_vpc_security_group" "k8s_nodes_ssh_access" {
  name        = "k8s-nodes-ssh-access"
  description = "Правила группы разрешают подключение к узлам кластера по SSH. Примените правила только для групп узлов."
  network_id  = yandex_vpc_network.cluster_network.id

  ingress {
    protocol       = "TCP"
    description    = "Правило разрешает подключение к узлам по SSH с указанных IP-адресов."
    v4_cidr_blocks = ["${var.service_ip}"]
    port           = 22
  }
}

resource "yandex_vpc_security_group" "k8s_master_whitelist" {
  name        = "k8s-master-whitelist"
  description = "Правила группы разрешают доступ к API Kubernetes из интернета. Примените правила только к кластеру."
  network_id  = yandex_vpc_network.cluster_network.id

  ingress {
    protocol       = "TCP"
    description    = "Правило разрешает подключение к API Kubernetes через порт 6443 из указанной сети."
    v4_cidr_blocks = ["${var.service_ip}"]
    port           = 6443
  }

  ingress {
    protocol       = "TCP"
    description    = "Правило разрешает подключение к API Kubernetes через порт 443 из указанной сети."
    v4_cidr_blocks = ["${var.service_ip}"]
    port           = 443
  }
}
