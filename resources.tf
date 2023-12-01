resource "yandex_iam_service_account" "docker-pusher" {
  name        = "docker-pusher"
  description = "service account to use container registry"
}

resource "yandex_resourcemanager_folder_iam_binding" "pusher" {
  folder_id  = var.yandex_cloud.folder_id
  role       = "container-registry.images.pusher"
  members    = ["serviceAccount:${yandex_iam_service_account.docker-pusher.id}"]
  depends_on = [yandex_iam_service_account.docker-pusher]
}

resource "yandex_iam_service_account" "instances-editor" {
  name        = "instances-editor"
  description = "service account to manage VMs"
}

resource "yandex_resourcemanager_folder_iam_binding" "editor" {
  folder_id  = var.yandex_cloud.folder_id
  role       = "editor"
  members    = ["serviceAccount:${yandex_iam_service_account.instances-editor.id}"]
  depends_on = [yandex_iam_service_account.instances-editor]
}

resource "yandex_vpc_network" "internal" {
  name = "internal"
}

resource "yandex_vpc_subnet" "internal-a" {
  name           = "internal-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.internal.id
  v4_cidr_blocks = ["10.200.0.0/16"]
}

resource "yandex_vpc_subnet" "internal-b" {
  name           = "internal-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.internal.id
  v4_cidr_blocks = ["10.201.0.0/16"]
}

resource "yandex_vpc_subnet" "internal-c" {
  name           = "internal-c"
  zone           = "ru-central1-c"
  network_id     = yandex_vpc_network.internal.id
  v4_cidr_blocks = ["10.202.0.0/16"]
}

resource "yandex_kubernetes_cluster" "k8s-test" {
  name       = "k8s-test"
  network_id = yandex_vpc_network.internal.id
  master {
    version   = var.kube_cluster.version
    public_ip = true
    zonal {
      zone      = yandex_vpc_subnet.internal-a.zone
      subnet_id = yandex_vpc_subnet.internal-a.id
    }

  }
  release_channel         = "RAPID"
  network_policy_provider = "CALICO"
  node_service_account_id = yandex_iam_service_account.docker-pusher.id
  service_account_id      = yandex_iam_service_account.instances-editor.id
  depends_on              = [yandex_iam_service_account.docker-pusher, yandex_iam_service_account.instances-editor]
}

resource "yandex_kubernetes_node_group" "test-group-auto" {
  name       = "test-group-auto"
  cluster_id = yandex_kubernetes_cluster.k8s-test.id
  version    = var.kube_cluster.version
  instance_template {
    platform_id = "standard-v2"
    network_interface {
      nat        = true
      subnet_ids = yandex_vpc_subnet.internal-a[*].id
    }
    resources {
      cores         = var.kube_cluster.res_cores
      core_fraction = var.kube_cluster.res_core_fraction
      memory        = var.kube_cluster.res_memory
    }
    boot_disk {
      type = var.kube_cluster.disk_type
      size = var.kube_cluster.disk_size
    }
    scheduling_policy {
      preemptible = false
    }
    container_runtime {
      type = "containerd"
    }
  }
  scale_policy {
    auto_scale {
      min     = var.kube_cluster.scale_min
      initial = var.kube_cluster.scale_initial
      max     = var.kube_cluster.scale_max
    }
  }
  allocation_policy {
    location {
      zone = "ru-central1-a"
    }
  }
}