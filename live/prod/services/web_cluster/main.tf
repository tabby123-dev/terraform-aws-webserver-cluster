terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "terraform-running"
    key            = "live/production/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}

module "webserver_cluster" {
  source = "../../../../modules/webserver_cluster"

  cluster_name  = "webservers-production"
  instance_type = "t3.micro"
  min_size      = 2
  max_size      = 4
}

output "alb_dns_name" {
  value = module.webserver_cluster.alb_dns_name
}