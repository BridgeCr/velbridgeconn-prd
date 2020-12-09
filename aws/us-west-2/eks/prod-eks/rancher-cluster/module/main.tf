
provider rancher2 {
  api_url = var.rancher_api_url
  token_key = var.rancher_api_token
  insecure = false
}


resource "rancher2_cluster" "this" {
  name = var.cluster_name
}