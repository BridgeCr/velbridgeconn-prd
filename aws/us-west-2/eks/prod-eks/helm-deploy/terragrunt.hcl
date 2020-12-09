terraform {
  source = "module"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

generate "empty_backend_s3" {
  path      = "backend.tf"
  if_exists = "overwrite"
  contents = <<EOF
terraform {
  backend "s3" {}
}
EOF
}

generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
variable "region" {}
provider "aws" {
  region  = var.region
  version = "~> 2.0"
}
EOF
}

dependencies {
  paths = ["../eks", "../rancher-cluster"]
}

dependency "eks" {
  config_path  = "../eks"
  skip_outputs = false

  mock_outputs = {
    cluster_id = "mock-cluster-id"
  }
}

dependency "rancher_import" {
  config_path  = "../rancher-cluster"
  skip_outputs = false

  mock_outputs = {
    register_command = "mock-register-command"
  }
}

inputs = merge(
  yamldecode(file(find_in_parent_folders("common_vars.yaml"))),
  yamldecode(file("values.yml")),

  {
    cluster_id = dependency.eks.outputs.cluster_id
    deploy_manifests  = []
    rancher_import_cmd = dependency.rancher_import.outputs.register_command
  }
)
