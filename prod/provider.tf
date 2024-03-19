terraform {

  cloud {
    organization = "Your-Organization-Name"

    workspaces {
      name = "your-workspace-name"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.15.0"
    }
  }

  required_version = ">= 0.14.0"
}

#Oganization Account Access Role-------Gen AI Account-----------

provider "aws" {
  region = "us-east-1"

  assume_role {
    role_arn = "your role arn"

  }
}
