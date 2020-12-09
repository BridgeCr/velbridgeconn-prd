output "register_command" {
  value = rancher2_cluster.this.cluster_registration_token[0].command
  sensitive = true
}

output "cluster_id" {
  value = rancher2_cluster.this.id
}

output "rke_yaml" {
  value = rancher2_cluster.this.rke_config
  sensitive = true
}

output "kube_config" {
  value = rancher2_cluster.this.kube_config
  sensitive = true
}

output "cluster_name" {
  value = var.cluster_name
}