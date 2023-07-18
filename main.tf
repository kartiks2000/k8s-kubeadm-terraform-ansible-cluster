terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  access_key = "AKIA257FKG6BAQHNVKNK"
  secret_key = "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"
}

# VPC
# resource "aws_vpc" "k8s_vpc" {
#   cidr_block       = "10.0.0.0/16"
#   enable_dns_hostnames = true

#   tags = {
#     Name = "k8s_vpc"
#   }
# }

# Subnet

# resource "aws_subnet" "k8s_subnet" {
#   vpc_id     = aws_vpc.k8s_vpc
#   cidr_block = "10.0.1.0/24"

#   tags = {
#     Name = "Main"
#   }
# }
