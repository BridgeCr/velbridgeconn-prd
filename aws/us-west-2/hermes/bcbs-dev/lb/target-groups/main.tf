variable "target_groups" {
  type = map
}
variable "listener_arn" {
  default = ""
}

variable "vpc_id" {
  default = ""
}

resource "aws_lb_target_group" "this" {
  for_each = var.target_groups
  name = each.key
  port = each.value["backend_port"]
  protocol = each.value["backend_protocol"]
  vpc_id = var.vpc_id
  health_check {
    enabled             = lookup(each.value, "enabled", null)
    interval            = lookup(each.value, "interval", null)
    path                = lookup(each.value, "path", null)
    port                = lookup(each.value, "backend_port", null)
    healthy_threshold   = lookup(each.value, "healthy_threshold", null)
    unhealthy_threshold = lookup(each.value, "unhealthy_threshold", null)
    timeout             = lookup(each.value, "timeout", null)
    protocol            = lookup(each.value, "protocol", null)
    matcher             = lookup(each.value, "matcher", null)
  }
}


resource "aws_lb_listener_rule" "host_based_weighted_routing" {
  for_each = var.target_groups

  listener_arn = var.listener_arn

  condition {
    path_pattern {
      values = [each.value["path_pattern"]]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.key].arn
  }

}

variable "instance_id" {
  default = ""
}

resource "aws_alb_target_group_attachment" "this" {
  for_each = var.target_groups
  target_group_arn = aws_lb_target_group.this[each.key].arn
  target_id = lookup(each.value, "instance_id", var.instance_id)
}

output "attachments" {
  value = aws_alb_target_group_attachment.this
  sensitive = true
}