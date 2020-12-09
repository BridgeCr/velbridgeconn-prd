terraform {
  source = "git::git@github.com:terraform-aws-modules/terraform-aws-vpc.git?ref=v2.33.0"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

locals {
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

inputs = merge(
  yamldecode(file("velbridgeconn-vpc.yaml")),
  yamldecode(file("${find_in_parent_folders("vpc_common_vars.yaml")}")),
  {
    // tags = {
    //   Env         = local.environment_vars.locals.environment
    //   TG_Managed  = true
    // }
  }
)
