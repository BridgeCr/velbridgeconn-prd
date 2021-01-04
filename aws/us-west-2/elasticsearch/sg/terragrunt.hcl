terraform {
  source = "git::git@github.com:terraform-aws-modules/terraform-aws-security-group.git"
}

include { 
  path = find_in_parent_folders() 
}

locals { 
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl")) 
}

dependency "vpc" {
  config_path  = "../../vpc"
  skip_outputs = false

  mock_outputs = {
    vpc_id = "mock-vpc-id"
  }
}

inputs = merge(
  yamldecode(file("../vars/sg.yaml")),
  yamldecode(file("${find_in_parent_folders("vpc_common_vars.yaml")}")),
  {
    vpc_id = dependency.vpc.outputs.vpc_id
  }
)
