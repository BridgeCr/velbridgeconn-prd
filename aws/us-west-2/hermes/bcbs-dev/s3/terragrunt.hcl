terraform {
  source = "git@github.com:terraform-aws-modules/terraform-aws-s3-bucket.git?ref=v1.6.0"
}

locals {
  env_common_vars = yamldecode(file("../env_common.yaml"))
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

inputs = merge(
  yamldecode(file("../vars/s3.yaml")),
  {
    provider_region = "us-west-2"
    bucket =  "${local.env_common_vars.name}-azblue-alb-logs"
    tags = merge(local.env_common_vars.tags, {
      Name = "${local.env_common_vars.name}-alb-logs"
      Description = "Hermes BCBS PRD ALB Logs"
    })
  }

)
