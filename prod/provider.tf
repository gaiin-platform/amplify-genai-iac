terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.63.0"
    }
  }
  required_version = ">= 0.14.0"
}

provider "aws" {
  region = "us-east-1"
  ignore_tags {
  keys = ["*"]
  }
}
