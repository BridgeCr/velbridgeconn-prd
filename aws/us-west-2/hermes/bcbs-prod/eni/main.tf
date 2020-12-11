variable "cidr_block" {
  type = string
}
variable "security_groups" {
  type = list(string)
}

variable "private_ips" {
  type = list(string)
}

variable "description" {
  type = string
  default = "terragrunt generated interface"
}

variable "tags" {
  type = map(string)
}

data "aws_subnet" "subnet" {
  cidr_block = var.cidr_block
}

resource "aws_network_interface" "this" {
  subnet_id       = data.aws_subnet.subnet.id
  private_ips     = var.private_ips
  security_groups = var.security_groups
  description = var.description
  tags = var.tags
}

output "net_if_id" {
  value = aws_network_interface.this.id
  sensitive = true
}