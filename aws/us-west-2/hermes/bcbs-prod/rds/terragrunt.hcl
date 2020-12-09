terraform {
  source = "git::git@github.com:terraform-aws-modules/terraform-aws-rds-aurora.git"
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
  config_path = "../../env-data"
  skip_outputs = false
}

inputs = merge(
  yamldecode(file("../vars/rds.yaml")),
  {
    provider_region = "us-west-2"
    vpc_id = dependency.vpc.outputs.vpc_id
    subnets =  length(dependency.vpc.outputs.private_database_subnet_ids) > 0 ? dependency.vpc.outputs.private_database_subnet_ids : dependency.vpc.outputs.private_subnet_ids
    allowed_cidr_blocks = concat(
        tolist(dependency.vpc.outputs.private_cidr_blocks),
        ["10.208.16.0/21"]
    )
    security_group_description = "${title(local.env_common_vars.description_prefix)} RDS Security Group"
    name = "${local.env_common_vars.name}-postgres"
    identifier = "${local.env_common_vars.name}-postgres"
    tags = merge(local.env_common_vars.tags, {
      Name = "${local.env_common_vars.name}-postgres"
    })
  }
)
