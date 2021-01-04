terraform {
  source = "git::https://github.com/cloudposse/terraform-aws-elasticsearch.git?ref=0.23.0"
}

include {
  path = find_in_parent_folders()
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  vpc_common_vars = yamldecode(file("${find_in_parent_folders("vpc_common_vars.yaml")}"))
}

dependency "vpc" {
  config_path  = "../../vpc"
  skip_outputs = false

  mock_outputs = {
    vpc_id = "mock-vpc-id"
    subnet_ids = ["mock-subnet-ids"]
  }
}

dependency "sg" {
  config_path  = "../sg"
  skip_outputs = false

  mock_outputs = {
    security_groups = ["mock-sg-ids"]
  }
}

inputs = merge(
  yamldecode(file("../vars/instance.yaml")),
  yamldecode(file("${find_in_parent_folders("vpc_common_vars.yaml")}")),
  {
    dns_zone_id     = local.vpc_common_vars.zone_id.bcrstage
    vpc_id          = dependency.vpc.outputs.vpc_id
    subnet_ids      = [dependency.vpc.outputs.private_subnets[0],dependency.vpc.outputs.private_subnets[2]]
    security_groups = [dependency.sg.outputs.this_security_group_id]
  }
)
