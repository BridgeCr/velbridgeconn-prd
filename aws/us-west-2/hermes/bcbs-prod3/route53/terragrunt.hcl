terraform {
  source = "git::git@github.com:clouddrove/terraform-aws-route53-record.git?ref=tags/0.12.1"
}

locals {
  env_common_vars = yamldecode(file("../env_common.yaml"))
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

dependencies {
  paths = ["../../env-data", "../lb/alb"]
}

dependency "vpc" {
  config_path  = "../../env-data"
  skip_outputs = false

  mock_outputs = {
    vpc_id = "mock-vpc-id"
  }
}

dependency "alb" {
  config_path  = "../lb/alb"
  skip_outputs = false

  mock_outputs = {
    this_lb_dns_name = "mock-name"
    this_lb_zone_id = "mock-zone-id"
  }
}

inputs = merge(
{
  provider_region = "us-east-1"
  zone_id = dependency.vpc.outputs.route53_zones[local.env_common_vars.bridge_domain].id
  name    = "${local.env_common_vars.r53_record}."
  type    = "A"
  alias   = {
    name = dependency.alb.outputs.this_lb_dns_name
    zone_id = dependency.alb.outputs.this_lb_zone_id
    evaluate_target_health = false
  }
  vpc_id = dependency.vpc.outputs.vpc_id
})
