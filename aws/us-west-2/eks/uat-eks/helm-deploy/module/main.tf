data "aws_eks_cluster" "cluster" {
  name = var.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}

provider "helm" {
  version = "~> 0.10.0"

  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
    load_config_file       = false
  }

}

# locals {
#   kube_config = "--server=${data.aws_eks_cluster.cluster.endpoint} --insecure-skip-tls-verify=true --token=${data.aws_eks_cluster_auth.cluster.token}"
# }

# resource "null_resource" "create_tiller_service_account" {
#   provisioner "local-exec" {
#     command = "kubectl ${local.kube_config} -n kube-system create serviceaccount tiller"
#   }
# }

# resource "null_resource" "create_tiller_cluster_role_binding" {
#   depends_on = [null_resource.create_tiller_service_account]

#   provisioner "local-exec" {
#     command = "kubectl ${local.kube_config} create clusterrolebinding tiller --clusterrole=cluster-admin --serviceaccount=kube-system:tiller"
#   }
# }
# resource "null_resource" "helm_init_tiller" {
#   depends_on = [null_resource.create_tiller_cluster_role_binding]

#   provisioner "local-exec" {
#     command = "helm init --service-account tiller"
#   }
# }

# resource "null_resource" "helm_init_override_tiller" {
#   depends_on = [null_resource.helm_init_tiller]

#   provisioner "local-exec" {
#     command = "helm init --service-account tiller --override spec.selector.matchLabels.'name'='tiller',spec.selector.matchLabels.'app'='helm' --output yaml | sed 's@apiVersion: extensions/v1beta1@apiVersion: apps/v1@' | kubectl ${local.kube_config} apply -f -"
#   }
# }

# resource "null_resource" "patch_tiller" {
#   depends_on = [null_resource.helm_init_override_tiller]

#   provisioner "local-exec" {
#     command = "kubectl ${local.kube_config} patch deploy --namespace kube-system tiller-deploy -p '{\"spec\":{\"template\":{\"spec\":{\"serviceAccount\":\"tiller\"}}}}' || true"
#   }
# }

resource "helm_release" "releases" {
  for_each = var.default_charts

  name       = each.key
  repository = each.value["repository"]
  chart      = each.value["chart_name"]
  version    = lookup(each.value, "version", null)
  namespace  = each.value["namespace"]
  values     = [file(lookup(each.value, "values", null))]
}

resource "null_resource" "deploy_manifests" {
  for_each = var.deploy_manifests

  provisioner "local-exec" {
    command = "kubectl --server=${data.aws_eks_cluster.cluster.endpoint} --insecure-skip-tls-verify=true --token=${data.aws_eks_cluster_auth.cluster.token} create -f ${each.key}"
  }
}

// resource "null_resource" "add_to_rancher" {
//   count = var.rancher_add ? 1 : 0

//   provisioner "local-exec" {
//     command = "${var.rancher_import_cmd} --server=${data.aws_eks_cluster.cluster.endpoint} --insecure-skip-tls-verify=true --token=${data.aws_eks_cluster_auth.cluster.token}"
//   }
// }