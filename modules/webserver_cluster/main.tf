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
  id = "sg-0a4c3ebecc7e40048"
}

resource "aws_launch_template" "web_app" {
  name_prefix            = "${var.cluster_name}-launchtemplate"
  image_id               = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [data.aws_security_group.my_sg.id]
  user_data = base64encode(templatefile("${path.module}/user-data.sh.tpl",{
    cluster_name = var.cluster_name
  }))

}
resource "aws_autoscaling_group" "web_asg" {
    name = "${var.cluster_name}-asg"
    desired_capacity = var.min_size
    min_size = var.min_size
    max_size = var.max_size
    vpc_zone_identifier = data.aws_subnets.default.ids
    launch_template {
      id = aws_launch_template.web_app.id
      version = "$Latest"
    }
    target_group_arns = [aws_lb_target_group.web_tg.arn]
    health_check_type = "ELB"
    tag {
        key = "Name"
        value = "${var.cluster_name}-webserver"
        propagate_at_launch = true

    }
  
}
resource "aws_lb" "web_lb" {
    name ="${var.cluster_name}-alb"
    internal = false
    load_balancer_type = "application"
    security_groups = [data.aws_security_group.my_sg.id]
    subnets = data.aws_subnets.default.ids
}
resource "aws_lb_target_group" "web_tg"{
    name = "${var.cluster_name}-webtg"
    port = 80
    protocol = "HTTP"
    vpc_id = data.aws_vpc.default.id
    health_check {
        path = "/"
        protocol = "HTTP"
        matcher = 200
        interval = 15
        timeout = 3
        healthy_threshold = 2
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

