terraform {
  source = "git::git@github.com:terraform-aws-modules/terraform-aws-security-group.git?ref=v3.16.0"
}

locals {
  env_common_vars = yamldecode(file("../env_common.yaml"))
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

dependencies {
  paths = ["../../env-data"]
}

dependency "vpc" {
  config_path  = "../../env-data"
  skip_outputs = false

  mock_outputs = {
    vpc_id = "mock-vpc-id"
  }
}

inputs = merge(
  yamldecode(file("../vars/instance-sg.yaml")),
  {
    provider_region = "us-west-2"
    name = "${local.env_common_vars.name}-instance-sg"
    description = "${local.env_common_vars.description_prefix} Instance Security Group"
    vpc_id = dependency.vpc.outputs.vpc_id
    tags = merge(local.env_common_vars.tags, {
      Name = "${local.env_common_vars.name}-instance-sg"
    })
  }
)
