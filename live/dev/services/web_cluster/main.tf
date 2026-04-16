terraform {

  backend "s3" {
    bucket         = "terraform-running"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}

module "webserver_cluster" {
  source = "../../../../modules/webserver_cluster"


  cluster_name  = "webservers-dev"
  instance_type = "t3.small"
  min_size      = 2
  max_size      = 4
}

output "alb_dns_name" {
  value = module.webserver_cluster.alb_dns_name
}