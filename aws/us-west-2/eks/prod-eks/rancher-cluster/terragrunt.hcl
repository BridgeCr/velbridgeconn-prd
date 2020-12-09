terraform {
  source = "module"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
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

dependencies {
  paths = ["../../../../hub/rancher-ha/rancher/bootstrap"]
}

dependency "bs" {
  config_path  = "../../../../hub/rancher-ha/rancher/bootstrap"
  skip_outputs = false

  mock_outputs = {
    rancher_api_token = "mock-api-token"
    rancher_api_url = "mock-api-url"
  }
}

inputs = merge(
{
    region = "us-east-1"
    cluster_name = "bridge-eks-prod-2"
    rancher_api_url = dependency.bs.outputs.rancher_api_url
    rancher_api_token = dependency.bs.outputs.rancher_api_token
  }
)
