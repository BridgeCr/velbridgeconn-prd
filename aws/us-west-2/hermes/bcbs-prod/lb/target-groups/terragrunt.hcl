
locals {
  env_common_vars = yamldecode(file("../../env_common.yaml"))
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

dependencies {
  paths = ["../../../env-data", "../alb", "../../instance"]
}

dependency "vpc" {
  config_path  = "../../../env-data"
  skip_outputs = false

  mock_outputs = {
    vpc_id = "mock-vpc-id"
  }
}

dependency "alb" {
  config_path  = "../alb"
  skip_outputs = false

  mock_outputs = {
    this_security_group_id = "mock-sg-id"
  }
}

dependency "instance" {
  config_path  = "../../instance"
  skip_outputs = false

  mock_outputs = {
    id = ["mock-id"]
  }
}

inputs = merge(
  yamldecode(file("../../vars/target-groups.yaml")),
  {
    provider_region = "us-west-2"
    listener_arn = element(dependency.alb.outputs.https_listener_arns, 0)
    vpc_id = dependency.vpc.outputs.vpc_id
    instance_id = element(tolist(dependency.instance.outputs.id), 0)
    tags = local.env_common_vars.tags
  }
)