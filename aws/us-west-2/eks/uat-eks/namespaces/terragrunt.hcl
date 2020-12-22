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

generate "providers" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents = <<EOF
variable "cluster_id" {}
variable "region" {}

provider "aws" {
  region = var.region
}

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
EOF
}

dependencies {
  paths = ["../eks"]
}

dependency "eks" {
  config_path  = "../eks"
  skip_outputs = false

  mock_outputs = {
    cluster_id = "mock-cluster-id"
  }
}
inputs = merge(
  yamldecode(file(find_in_parent_folders("common_vars.yaml"))),
  yamldecode(file("values.yml")),
  {
    cluster_id = dependency.eks.outputs.cluster_id
  }
)
