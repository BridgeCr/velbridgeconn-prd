terraform {
    source = "git@github.com:beppenstein/terraform-module-vpc-data.git"
}

locals {
  vpc_common_vars = yamldecode(file("${find_in_parent_folders("vpc_common_vars.yaml")}"))
}

include {
  path = find_in_parent_folders()
}

inputs = {
  region = "us-west-2"
  provider_region = "us-west-2"
  vpc_name = local.vpc_common_vars.vpc_name
  r53_domains = local.vpc_common_vars.bridge_domains
  buckets = local.vpc_common_vars.buckets
}