variable "cluster_id" {
  description = "Kubernetes cluster ID from the EKS module."
}

variable "default_charts" {
  type        = map
  description = <<EOF
    A map of maps to define default helm charts.

    Key: Name of the release (appname)

    Values:
      - `repository:` Name of the repository (required)
      - `chart_name:` Name of the chart (required)
      - `namespace:` Namespace of where the chart should be deployed (required)
      - `version:` Specific version of the chart. Uses latest if not provided (optional)
      - `values:` File path to values file for chart (optional)

    Example:
    ```
    default_charts = {
      aws-alb = {
        repository = ""https://charts.helm.sh/incubator""
        chart_name = "aws-alb-ingress-controller"
        namespace = "devops-utils"
        version = "1.0.0"
        values = "helm_values/aws-alb_values.yml"
      }
    }
    ```
EOF
}

variable "deploy_manifests" {
  type = set(string)
  description = "Set (list) of Kubernetes manifests. Requires the full path to the manifest."
}

variable "rancher_add" {
  description = "Whether or not to add the manifest(s) to Rancher."
  default     = true
}

variable "rancher_import_cmd" {
  description = "kubectl command to import into Rancher."
  default     = ""
}