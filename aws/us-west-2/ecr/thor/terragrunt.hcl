terraform {
  source = "git::git@github.com:/lgallard/terraform-aws-ecr.git?ref=0.3.0"
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
  yamldecode(file("ecr.yaml")),
  {
    // tags = {
    //   Env         = local.environment_vars.locals.environment
    //   TG_Managed  = true
    // }
  }
)