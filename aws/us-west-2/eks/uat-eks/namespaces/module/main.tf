resource "kubernetes_namespace" "namespaces" {
  for_each = var.namespaces

  metadata {
    name = each.key
  }
}

resource "kubernetes_limit_range" "limit_ranges" {
  depends_on = [kubernetes_namespace.namespaces]
  for_each = var.namespaces

  metadata {
    namespace = each.key
    name = "${each.key}-limit-range"
  }
  spec {
    limit {
      type = "Pod"
      max = {
        cpu    = lookup(each.value, "lr_pod_max_cpu", "500m")
        memory = lookup(each.value, "lr_pod_max_mem", "512Mi")
      }
    }
    limit {
      type = "Container"
      default = {
        cpu    = lookup(each.value, "lr_con_default_cpu", "250m")
        memory = lookup(each.value, "lr_con_default_mem", "256Mi")
      }
      max = {
        cpu    = lookup(each.value, "lr_con_max_cpu", "500m")
        memory = lookup(each.value, "lr_con_max_mem", "512Mi")
      }
    }
  }
}

resource "kubernetes_resource_quota" "quotas" {
  depends_on = [kubernetes_namespace.namespaces]
  for_each = var.namespaces

  metadata {
    namespace = each.key
    name = "${each.key}-quota"
  }
  spec {
    hard = {
      pods = lookup(each.value, "quota_pods", "30")
      "limits.cpu" = lookup(each.value, "quota_cpu", "2")
      "limits.memory" = lookup(each.value, "quota_mem", "2048Mi")
    }
  }
}

data "aws_s3_bucket_object" "elastic_s3_secret" {
  bucket = "azblue-bcr-automation-secrets"
  key = "terraform/elastic_auth.json"
}

resource "kubernetes_secret" "elastic_k8s_secret" {
  metadata {
    name = "elastic-auth"
    namespace = "devops-utils"
  }
  data = jsondecode(data.aws_s3_bucket_object.elastic_s3_secret.body)
}