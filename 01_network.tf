resource "aws_vpc" "main" {
  cidr_block = var.network.vpc_cidr
}
resource "aws_security_group" "nsg" {
  count  = length(var.network.nsg)
  name   = "${var.main.name}-${var.network.nsg[count.index].name}"
  vpc_id = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.network.nsg[count.index].ingress
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      self        = ingress.value.self
    }
  }

  dynamic "egress" {
    for_each = var.network.nsg[count.index].egress
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
      self        = egress.value.self
    }
  }
}
