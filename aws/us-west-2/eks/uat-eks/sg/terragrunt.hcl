terraform {
  source = "git::git@github.com:terraform-aws-modules/terraform-aws-security-group.git"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

dependencies {
  paths = ["../../../vpc"]
}

dependency "vpc" {
  config_path  = "../../../vpc"
  skip_outputs = false

  mock_outputs = {
    vpc_id = "mock-vpc-id"
  }
}

inputs = merge(
  yamldecode(file("sg_values.yaml")),
  {
    region = "us-west-2"
    vpc_id = dependency.vpc.outputs.vpc_id
  })

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
