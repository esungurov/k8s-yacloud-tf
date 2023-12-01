# Terraform manifest to create zoned k8s cluster

Small manifest to deploy **Zone** cluster. With a small changes you could make this cluster **Regional**, since it's creating additional subnets.

Replace this section
```
    zonal {
      zone      = yandex_vpc_subnet.internal-a.zone
      subnet_id = yandex_vpc_subnet.internal-a.id
    }
```

With something like this

```
    regional {
      region = "ru-central1"

      location {
        zone      = yandex_vpc_subnet.internal-a.zone
        subnet_id = yandex_vpc_subnet.internal-a.id
      }

      location {
        zone      = yandex_vpc_subnet.internal-b.zone
        subnet_id = yandex_vpc_subnet.internal-b.id
      }

      location {
        zone      = yandex_vpc_subnet.internal-c.zone
        subnet_id = yandex_vpc_subnet.internal-c.id
      }
    }
```
You also would need to create keyfile with YC CLI

```
yc iam key create \
  --service-account-id <service_account_id> \
  --folder-name <folder_name> \
  --output key.json
```
## Additional links

[yandex_kubernetes_cluster resouce documentation](https://terraform-provider.yandexcloud.net//Resources/kubernetes_cluster)

[Getting Started with terraform](https://cloud.yandex.com/en/docs/tutorials/infrastructure-management/terraform-quickstart#before-you-begin)