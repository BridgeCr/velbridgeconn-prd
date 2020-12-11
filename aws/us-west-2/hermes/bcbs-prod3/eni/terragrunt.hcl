
locals {
  env_common_vars = yamldecode(file("../env_common.yaml"))
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

dependencies {
  paths = ["../../env-data", "../instance-sg", "../lb/sg"]
}

dependency "vpc" {
  config_path  = "../../env-data"
  skip_outputs = false

  mock_outputs = {
    vpc_id = "mock-vpc-id"
  }
}

dependency "sg" {
  config_path  = "../instance-sg"
  skip_outputs = false

  mock_outputs = {
    this_security_group_id = "mock-gs-id"
  }
}

dependency "albsg" {
  config_path  = "../lb/sg"
  skip_outputs = false

  mock_outputs = {
    this_security_group_id = "mock-gs-id"
  }
}

inputs = merge(
  yamldecode(file("../vars/eni.yaml")),
  {
  provider_region = "us-west-2"
  security_groups = [dependency.sg.outputs.this_security_group_id, dependency.albsg.outputs.this_security_group_id]
  description = "${local.env_common_vars.description_prefix} network interface"
  tags = merge(local.env_common_vars.tags, {
    Name = "${local.env_common_vars.name}-eni"
  })
})