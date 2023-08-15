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
  access_key = "AKIAY4FPF6UJANAMSQCM"
  secret_key = "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"
}