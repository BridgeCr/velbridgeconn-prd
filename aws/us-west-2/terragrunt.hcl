# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT CONFIGURATION
# Terragrunt is a thin wrapper for Terraform that provides extra tools for working with multiple Terraform modules,
# remote state, and locking: https://github.com/gruntwork-io/terragrunt
# ---------------------------------------------------------------------------------------------------------------------
remote_state {
  backend = "s3"

  config = {
    encrypt        = false
    bucket         = "tf-velbridgeconn-prd"
    key            = "aws/us-west-2/velbridgeconn-prd/${path_relative_to_include()}/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "velbridgeconn-prd-tf-state-lock"
  }
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
variable "provider_region" {}
provider "aws" {
  region  = var.provider_region
}
EOF
}

inputs = {
  region = "us-west-2"
  // This is because some modules re-define region and our generated provider needs the provider when it is not defined
  // It is dumb but no better ideas yet
  provider_region = "us-west-2"
}