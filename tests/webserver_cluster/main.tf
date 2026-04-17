provider "aws" {
  region = "us-east-1"
}

module "web" {
  source = "../../modules/webserver_cluster"

  cluster_name  = "test-cluster"
  instance_type = "t2.micro"
  min_size      = 1
  max_size      = 2
}