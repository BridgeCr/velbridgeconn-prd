terraform {
  source = "git::git@github.com:terraform-aws-modules/terraform-aws-eks.git?ref=v12.1.0"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

dependencies {
  paths = ["../../../vpc", "../sg"]
}


dependency "vpc" {
  config_path  = "../../../vpc"
  skip_outputs = false

  mock_outputs = {

    vpc_id = "mock-vpc-id"
  }
}

dependency "sg" {
  config_path  = "../sg"
  skip_outputs = false

  mock_outputs = {
    this_security_group_id = "mock-sg-id"
    this_security_group_vpc_id = "mock-vpc-id"
  }
}


generate "empty_backend_s3" {
  path      = "backend.tf"
  if_exists = "overwrite"
  contents = <<EOF
terraform {
  backend "s3" {}
}
EOF
}

generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
variable "region" {}
provider "aws" {
  region  = var.region
  version = "~> 2.0"
}
EOF
}


inputs = merge(
  yamldecode(file("values.yaml")),
  yamldecode(file(find_in_parent_folders("common_vars.yaml"))),
  {
    vpc_id = dependency.vpc.outputs.vpc_id
    subnets = dependency.vpc.outputs.private_subnets
    cluster_security_group_id = dependency.sg.outputs.this_security_group_id
    worker_create_security_group = false
    worker_security_group_id = dependency.sg.outputs.this_security_group_id
    config_output_path = "${get_terragrunt_dir()}/"
    cluster_name         = "azbcbs-prod"
    workers_additional_policies = [
        "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
        "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM",
        "arn:aws:iam::499898277306:policy/ExternalDNSManagement",
        "arn:aws:iam::499898277306:policy/ELB-Management"
      ]
    worker_groups = [
      {
        asg_desired_capacity = 5
        asg_max_size         = 7
        asg_min_size         = 5
        instance_type        = "c5.large"
        name                 = "eks-prod"
        subnets              = dependency.vpc.outputs.private_subnets
        key_name             = "bridge"
        additional_userdata  = templatefile("files/userdata.sh", {
        cluster_name         = "azbcbs-prod"
        })
        kubelet_extra_args   = "--node-labels=pool=azbcbs,nodegroup=azbcbs"

        tags = [
          {
            key                 = "EC2KeyName"
            value               = "bridge"
            propagate_at_launch = true
          },
          {
            key                 = "Service"
            value               = "azbcbs-prod"
            propagate_at_launch = true
          },
          {
            key                 = "Cluster"
            value               = "azbcbs-prod"
            propagate_at_launch = true
          },
          {
            key                 = "kubernetes.io/cluster/azbcbs-prod"
            value               = "owned"
            propagate_at_launch = true
          },
          {
            key                 = "Patch"
            value               = "yes"
            propagate_at_launch = true
          },
          {
            key                 = "Patch Group"
            value               = "AmazonLinux2"
            propagate_at_launch = true
          },
          {
            key                 = "Role"
            value               = "worker"
            propagate_at_launch = true
          },
          {
            key                 = "TG_Managed"
            value               = "true"
            propagate_at_launch = true
          }
        ]
      },
    ]
  }
)
