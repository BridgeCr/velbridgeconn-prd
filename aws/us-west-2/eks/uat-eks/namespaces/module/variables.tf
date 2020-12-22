variable "namespaces" {
  type        = map
  description = <<EOF
    A map of maps to define namespaces.

    Key: Name of the namespace

    Values:
      - `quota_pods:` (quota) Number of pods namespace is allowed to use (optional)
      - `quota_memory:` (quota) Amount of memory namespace is allowed to use (optional)
      - `quota_cpu:` (quota) Number of CPUs namespace is allowed to use. Use "1" for one CPU and "1500m" for 1.5 CPUs. (optional)
      - `lr_pod_max_cpu:` (limit range) Number of CPUs each pod within the namespace is allowed to use. If null, uses defaults. (optional)
      - `lr_pod_max_mem:` (limit range) Amount of memory each pod within the namespace is allowed to use. If null, uses defaults. (optional)
      - `lr_con_default_cpu:` (limit range) Default number of CPUs each container within the namespace is allowed to use. If null, uses defaults. (optional)
      - `lr_con_default_mem:` (limit range) Default amount of memory each container within the namespace is allowed to use. If null, uses defaults. (optional)
      - `lr_con_max_cpu:` (limit range) Maximum number of CPUs each container within the namespace is allowed to use. If null, uses defaults. (optional)
      - `lr_con_max_mem:` (limit range) Maximum amount of memory each container within the namespace is allowed to use. If null, uses defaults. (optional)

    Example:
    ```
    namespaces = {
      devops-utils = {
        quota_pods = "50"
        quota_mem = "2Gi"
        quota_cpu = "2"
        lr_pod_max_cpu = "500m"
        lr_pod_max_mem = "256Mi"
        lr_con_default_cpu = "250m"
        lr_con_default_mem = "256Mi"
        lr_con_max_cpu = "500m"
        lr_con_max_mem = "512Mi"
      }
    }
    ```
EOF
}