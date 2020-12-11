terraform {
  source = "git::git@github.com:terraform-aws-modules/terraform-aws-ec2-instance.git?ref=v2.15.0"
}


locals {
  env_common_vars = yamldecode(file("../env_common.yaml"))
  vpc_common_vars = yamldecode(file("${find_in_parent_folders("vpc_common_vars.yaml")}"))
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

dependencies {
  paths = ["../../env-data", "../instance-sg", "../rds"]
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
    this_security_group_id = "mock-sg-id"
  }
}

dependency "rds" {
  config_path  = "../rds"
  skip_outputs = false

  mock_outputs = {
    this_rds_cluster_endpoint = "mock-endpoint"
    this_rds_cluster_reader_endpoint = "mock-ro-endpoint"
    this_rds_cluster_master_username = "mock-username"
    this_rds_cluster_master_password = "mock-password"
    this_rds_cluster_database_name = "mock-database-name"
  }
}

dependency "net_if" {
  config_path  = "../eni"
  skip_outputs = false

  mock_outputs = {
    net_if_id = "mock-net_if_id"
  }
}

inputs = merge(
  yamldecode(file("../vars/instance.yaml")),
  {
    name  = local.env_common_vars.name
    provider_region = "us-east-1"
    description = "${local.env_common_vars.description_prefix} Instance"
    user_data = templatefile("../../templates/hermes_userdata.tpl.sh", {
      version = local.env_common_vars.hermes_version
      db_endpoint = dependency.rds.outputs.this_rds_cluster_endpoint
      db_ro_endpoint = dependency.rds.outputs.this_rds_cluster_reader_endpoint
      db_username = dependency.rds.outputs.this_rds_cluster_master_username
      db_password = dependency.rds.outputs.this_rds_cluster_master_password
      db_name = dependency.rds.outputs.this_rds_cluster_database_name
      region = local.vpc_common_vars.region
      env = "${local.env_common_vars.name}"
      nessus_group_name = "Hermes"
    })
    tags = merge(local.env_common_vars.tags, {
      Name = "${local.env_common_vars.name}"
    })
    primary_network_interface_id = dependency.net_if.outputs.net_if_id
    network_interface = [
      {
        device_index          = 0
        network_interface_id  = dependency.net_if.outputs.net_if_id
        delete_on_termination = false
      }
    ]
    vpc_id = dependency.vpc.outputs.vpc_id
  }
)