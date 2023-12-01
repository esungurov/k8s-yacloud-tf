terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.100"
    }
  }
}

provider "yandex" {
  service_account_key_file = file(var.yandex_key)
  cloud_id                 = var.yandex_cloud.cloud_id
  folder_id                = var.yandex_cloud.folder_id
  zone                     = var.yandex_cloud.zone
}