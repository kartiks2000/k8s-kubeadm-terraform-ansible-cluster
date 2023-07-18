terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source = "hashicorp/tls"
      version = "4.0.4"
    }

  }
}

# Configure the AWS Provider
provider "aws" {
  access_key = "AKIAVV2QUHJDR6L4XF2U"
  secret_key = "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"
}

# VPC
resource "aws_vpc" "k8s_vpc" {
  cidr_block       = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "k8s_vpc"
  }
}

# Subnet

resource "aws_subnet" "k8s_subnet" {
  vpc_id     = aws_vpc.k8s_vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "k8s_subnet"
  }
}

# Internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.k8s_vpc.id

  tags = {
    Name = "igw"
  }
}


# Route
resource "aws_route_table" "k8s_route_table" {
  vpc_id = aws_vpc.k8s_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "k8s_route_table"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.k8s_subnet.id
  route_table_id = aws_route_table.k8s_route_table.id
}


# Security Groups

# What is flannel?
# https://www.velotio.com/engineering-blog/flannel-a-network-fabric-for-containers#:~:text=Flannel%3A%20a%20solution%20for%20networking%20for%20Kubernetes

resource "aws_security_group" "sg_flannel" {
  name = "flannel-overlay-backend"
  vpc_id      = aws_vpc.k8s_vpc.id
  tags = {
    Name = "Flannel Overlay backend"
  }

  ingress {
    description = "flannel overlay backend"
    protocol = "udp"
    from_port = 8285
    to_port = 8285
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "flannel vxlan backend"
    protocol = "udp"
    from_port = 8472
    to_port =  8472
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sg_common" {
  name = "common-ports"
  vpc_id      = aws_vpc.k8s_vpc.id
  tags = { 
    Name = "common ports"
  }
  
  ingress {
    description = "Allow SSH"
    protocol = "tcp"
    from_port = 22
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    protocol = "tcp"
    from_port = 80
    to_port = 80 
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    protocol = "tcp"
    from_port = 443
    to_port = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sg_control_plane" {
  name = "kubeadm-control-plane security group"
  vpc_id      = aws_vpc.k8s_vpc.id
  ingress {
    description = "API Server"
    protocol = "tcp"
    from_port = 6443
    to_port = 6443
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kubelet API"
    protocol = "tcp"
    from_port = 2379
    to_port = 2380
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "etcd server client API"
    protocol = "tcp"
    from_port = 10250
    to_port = 10250
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kube Scheduler"
    protocol = "tcp"
    from_port = 10259
    to_port = 10259
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kube Contoller Manager"
    protocol = "tcp"
    from_port = 10257
    to_port = 10257
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { 
    Name = "Control Plane SG"
  }
}


resource "aws_security_group" "sg_worker_nodes" {
  name = "kubeadm-worker-node security group"
  vpc_id      = aws_vpc.k8s_vpc.id
  ingress {
    description = "kubelet API"
    protocol = "tcp"
    from_port = 10250
    to_port = 10250
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "NodePort services"
    protocol = "tcp"
    from_port = 30000
    to_port = 32767
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { 
    Name = "Worker Nodes SG"
  }
}


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
    command = "echo 'master ${self.public_ip}' >> ./files/hosts"
  }
}

resource "aws_instance" "worker_nodes" {
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
    command = "echo 'worker-${count.index} ${self.public_ip}' >> ./files/hosts"
  }
  
}





