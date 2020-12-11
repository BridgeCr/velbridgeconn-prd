terraform {
  source = "git::git@github.com:terraform-aws-modules/terraform-aws-alb.git?ref=v5.4.0"
}

locals {
  env_common_vars = yamldecode(file("../../env_common.yaml"))
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

dependencies {
  paths = ["../../../env-data", "../sg", "../../s3", "../../../../vpc"]
}

dependency "vpc" {
  config_path  = "../../../../vpc"
  skip_outputs = false

  mock_outputs = {
    vpc_id = "mock-vpc-id"
    public_subnet = ["mock-public-subnet-id"]
    private_subnet_ids = ["mock-private-subnet-id"]
  }
}

dependency "env" {
  config_path  = "../../../env-data"
  skip_outputs = false

  mock_outputs = {
    vpc_id = "mock-vpc-id"
    public_subnet_ids = ["mock-public-subnet-id"]
    private_subnet_ids = ["mock-private-subnet-id"]
  }
}

dependency "alb-sg" {
  config_path  = "../sg"
  skip_outputs = false

  mock_outputs = {
    this_security_group_id = "mock-sg-id"
  }
}

dependency "s3" {
  config_path  = "../../s3"
  skip_outputs = false

  mock_outputs = {
    this_s3_bucket_id = "mock-s3-bucket-id"
  }
}

inputs = merge(
  yamldecode(file("../../vars/alb.yaml")),
  {
    provider_region = "us-west-2"
    name = "${local.env_common_vars.name}-external-alb"
    security_groups = [dependency.alb-sg.outputs.this_security_group_id]
    subnets = dependency.vpc.outputs.public_subnets
    vpc_id = dependency.vpc.outputs.vpc_id
    tags = merge(local.env_common_vars.tags, {
      Name = "${local.env_common_vars.name}-external-alb"
    })

    access_logs = {
      bucket = dependency.s3.outputs.this_s3_bucket_id
    }

    load_balancer_type = "application"

    https_listeners = [
      {
        certificate_arn = dependency.env.outputs.certs[local.env_common_vars.bridge_domain].arn
        port = 443
        protocol = "HTTPS"
        action_type = "fixed-response"
        fixed_response = {
          content_type = "text/plain"
          message_body = "Path not Found"
          status_code = 404
        }
      }
    ]
  }
)
