
locals {
  retry_join = "provider=aws tag_key=NomadJoinTag tag_value=auto-join"
}
data "aws_ami" "os" {
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
resource "local_file" "cloud_pem" {
  filename = "${path.module}/cloudtls.pem"
  content  = tls_private_key.private_key.private_key_pem
}
resource "aws_key_pair" "generated_key" {
  key_name   = "${var.main.name}-key"
  public_key = tls_private_key.private_key.public_key_openssh
}
#
# locals {
#   instances_count = merge([
#     for key, val in var.compute.compute.instances :
#     {
#       for idx in range(val.count) :
#       "${key}-${idx}" => {
#         nomad_type    = key
#         instance_type = val.instance_type
#         device        = val.device
#       }
#     }
#   ]...)
# }
resource "aws_instance" "server" {
  ami           = data.aws_ami.os.id
  instance_type = var.compute.type.server.instance_type
  key_name      = aws_key_pair.generated_key.key_name
  subnet_id     = aws_subnet.main.id
  # vpc_security_group_ids = [aws_security_group.nomad_ui_ingress.id, aws_security_group.ssh_ingress.id, aws_security_group.allow_all_internal.id]
  vpc_security_group_ids = [
    for nsg_name in var.compute.type.server.nsgs :
    aws_security_group.nsg[nsg_name].id
  ]
  # associate_public_ip_address = true
  count = var.compute.type.server.count

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.private_key.private_key_pem
    host        = self.public_ip
  }

  # NomadJoinTag is necessary for nodes to automatically join the cluster
  tags = merge(
    {
      "Name" = "${var.main.name}-server-${count.index}"
    },
    {
      "NomadJoinTag" = "auto-join"
    },
    {
      "NomadType" = "server"
    }
  )

  root_block_device {
    volume_type           = var.compute.type.server.device.volume_type
    volume_size           = var.compute.type.server.device.volume_size
    delete_on_termination = var.compute.type.server.device.delete_on_termination
  }

  provisioner "remote-exec" {
    inline = ["sudo mkdir -p /ops", "sudo chmod 777 -R /ops"]
  }

  provisioner "file" {
    source      = "nomad_scripts"
    destination = "/ops"
  }

  user_data = templatefile("nomad_scripts/data-scripts/user-data-server.sh", {
    server_count  = var.compute.type.server.count
    region        = var.main.region
    cloud_env     = "aws"
    retry_join    = local.retry_join
    nomad_version = var.main.nomad_version
  })
  iam_instance_profile = aws_iam_instance_profile.instance_profile.name

  metadata_options {
    http_endpoint          = "enabled"
    instance_metadata_tags = "enabled"
  }
}

resource "aws_instance" "client" {
  ami           = data.aws_ami.os.id
  instance_type = var.compute.type.server.instance_type
  key_name      = aws_key_pair.generated_key.key_name
  subnet_id     = aws_subnet.main.id
  # vpc_security_group_ids = [aws_security_group.nomad_ui_ingress.id, aws_security_group.ssh_ingress.id, aws_security_group.allow_all_internal.id]
  vpc_security_group_ids = [
    for nsg_name in var.compute.type.server.nsgs :
    aws_security_group.nsg[nsg_name].id
  ]
  # associate_public_ip_address = true
  count = var.compute.type.server.count

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.private_key.private_key_pem
    host        = self.public_ip
  }

  # NomadJoinTag is necessary for nodes to automatically join the cluster
  tags = merge(
    {
      "Name" = "${var.main.name}-client-${count.index}"
    },
    {
      "NomadJoinTag" = "auto-join"
    },
    {
      "NomadType" = "client"
    }
  )

  root_block_device {
    volume_type           = var.compute.type.client.device.volume_type
    volume_size           = var.compute.type.client.device.volume_size
    delete_on_termination = var.compute.type.client.device.delete_on_termination
  }

  ebs_block_device {
    device_name           = "/dev/xvdd"
    volume_type           = "gp2"
    volume_size           = "50"
    delete_on_termination = "true"
  }

  provisioner "remote-exec" {
    inline = ["sudo mkdir -p /ops", "sudo chmod 777 -R /ops"]
  }

  provisioner "file" {
    source      = "nomad_scripts"
    destination = "/ops"
  }

  user_data = templatefile("nomad_scripts/data-scripts/user-data-client.sh", {
    region        = var.main.region
    cloud_env     = "aws"
    retry_join    = local.retry_join
    nomad_version = var.main.nomad_version
  })
  iam_instance_profile = aws_iam_instance_profile.instance_profile.name

  metadata_options {
    http_endpoint          = "enabled"
    instance_metadata_tags = "enabled"
  }
}
#
data "aws_iam_policy_document" "instance_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
resource "aws_iam_instance_profile" "instance_profile" {
  name_prefix = var.main.name
  role        = aws_iam_role.instance_role.name
}

resource "aws_iam_role" "instance_role" {
  name_prefix        = var.main.name
  assume_role_policy = data.aws_iam_policy_document.instance_role.json
}
resource "aws_iam_role_policy" "auto_discover_cluster" {
  name   = "${var.main.name}-auto-discover-cluster"
  role   = aws_iam_role.instance_role.id
  policy = data.aws_iam_policy_document.auto_discover_cluster.json
}

data "aws_iam_policy_document" "auto_discover_cluster" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
      "autoscaling:DescribeAutoScalingGroups",
    ]

    resources = ["*"]
  }
}
