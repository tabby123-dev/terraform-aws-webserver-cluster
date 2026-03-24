# Reusable Terraform Module: Webserver Cluster

Built my first reusable Terraform module!  

Reusable Terraform modules allow the reuse of Terraform configurations across environments, simplifying deployments so that you do not have to rewrite the same code every time.  

Today I created a module that deploys a highly available web server cluster across dev and prod environments. The only changes between environments are the variables.

## Project Structure
DAY8/
├── modules/
│ └── services/
│ └── webserver-cluster/
│ ├── main.tf
│ ├── variables.tf
│ ├── outputs.tf
└── live/
├── dev/
│ └── services/
│ └── webserver-cluster/
│ └── main.tf
└── production/
└── services/
└── webserver-cluster/
└── main.tf

## Sample Module Code (`modules/services/webserver-cluster/main.tf`)

```hcl
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_security_group" "my_sg" {
  id = "sg-0a4"
}

resource "aws_launch_template" "web_app" {
  name_prefix            = "${var.cluster_name}-launchtemplate"
  image_id               = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [data.aws_security_group.my_sg.id]
  user_data = base64encode(<<-EOF
                #!/bin/bash
                yum update -y
                yum install -y httpd
                systemctl start httpd
                systemctl enable httpd
                echo "<h1>Hello from ${var.cluster_name}! Welcome to DAY8 by </h1>" > /var/www/html/index.html
                EOF
                )
}

resource "aws_autoscaling_group" "web_asg" {
  name               = "${var.cluster_name}-asg"
  desired_capacity   = var.min_size
  min_size           = var.min_size
  max_size           = var.max_size
  vpc_zone_identifier = data.aws_subnets.default.ids

  launch_template {
    id      = aws_launch_template.web_app.id
    version = "$Latest"
  }

  target_group_arns  = [aws_lb_target_group.web_tg.arn]
  health_check_type  = "ELB"

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-webserver"
    propagate_at_launch = true
  }
}

resource "aws_lb" "web_lb" {
  name               = "${var.cluster_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.my_sg.id]
  subnets            = data.aws_subnets.default.ids
}

resource "aws_lb_target_group" "web_tg" {
  name     = "${var.cluster_name}-webtg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = 200
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.web_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}
Sample Dev Environment Code (live/dev/services/webserver-cluster/main.tf)
terraform {
  backend "s3" {
    bucket  = "your-bucket-name"
    key     = "live/dev/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = "us-east-1"
}

module "webserver_cluster" {
  source        = "../../../../modules/webserver-cluster"
  cluster_name  = "webservers-dev"
  instance_type = "t3.small"
  min_size      = 2
  max_size      = 4
}

output "alb_dns_name" {
  value = module.webserver_cluster.alb_dns_name
}
How to Run Dev Environment
cd live/dev/services/webserver-cluster
terraform init
terraform plan
terraform apply
How to Run Production Environment
cd live/production/services/webserver-cluster
terraform init
terraform plan
terraform apply

After a successful apply, you should get the ALB DNS name:

alb_dns_name = "webserver-dev-alb-xxxxxxxxxx.us-east-1.elb.amazonaws.com"
alb_dns_name = "webserver-prod-alb-xxxxxxxxxx.us-east-1.elb.amazonaws.com"