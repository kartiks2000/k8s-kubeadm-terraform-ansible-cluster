# Key pair
resource "tls_private_key" "private_key" {
  
  algorithm = "RSA"
  rsa_bits  = 4096

  provisioner "local-exec" { # Create a "pubkey.pem" to your computer!!
    command = "echo '${self.public_key_pem}' > ./pubkey.pem"
  }
}

resource "aws_key_pair" "key_pair" {
  key_name = var.keypair_name
  public_key = tls_private_key.private_key.public_key_openssh

  provisioner "local-exec" { # Create a "myKey.pem" to your computer!!
    command = "echo '${tls_private_key.private_key.private_key_pem}' > ./private-key.pem"
  }
}  

# Instances

# Control plane (Master)
resource "aws_instance" "k8s_control_plane" {
  subnet_id = aws_subnet.k8s_subnet.id
  ami = var.ubuntu_ami
  instance_type = "t2.medium"
  key_name = aws_key_pair.key_pair.key_name
  associate_public_ip_address = true
  security_groups = [
    aws_security_group.sg_common.id,
    aws_security_group.sg_flannel.id,
    aws_security_group.sg_control_plane.id,
  ]
  root_block_device {
    volume_type = "gp2"
    volume_size = 14
  }

  tags = {
    Name = "k8s_control_plane"
    Role = "Control plane node"
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo '[master]' >> ./k8s_nodes.yaml
      echo 'master-0 ansible_host=${self.public_ip}' >> k8s_nodes.yaml
    EOT
  }
}

resource "aws_instance" "k8s_worker_nodes" {
  count = var.worker_nodes_count
  subnet_id = aws_subnet.k8s_subnet.id
  ami = var.ubuntu_ami
  instance_type = "t2.small"
  key_name = aws_key_pair.key_pair.key_name
  associate_public_ip_address = true
  security_groups = [
    aws_security_group.sg_flannel.id,
    aws_security_group.sg_common.id,
    aws_security_group.sg_worker_nodes.id,
  ]
  root_block_device {
    volume_type = "gp2"
    volume_size = 8
  }

  tags = {
    Name = "Kubeadm Worker ${count.index}"
    Role = "Worker node"
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo '[workers]' >> ./k8s_nodes.yaml
      echo 'worker-${count.index} ansible_host=${self.public_ip}' >> ./k8s_nodes.yaml
    EOT
  }
}
