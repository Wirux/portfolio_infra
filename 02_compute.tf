
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  dynamic "filter" {
    for_each = var.compute.ami.filters
    content {
      name   = filter.value.name
      values = filter.value.values
    }
  }
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "tf-key"
  public_key = tls_private_key.private_key.public_key_openssh
}
