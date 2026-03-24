# Terraform Module: Gotchas

## Overview
This Terraform module provisions  highly available web server cluster on AWS using an Auto Scaling Group and Application Load Balancer. It is designed to be reusable across environments by exposing configuration via input variables and providing key resource identifiers via outputs.

---

## Inputs

| Name | Type | Description | Default | Required |
|------|------|-------------|---------|----------|
| `cluster_name` | `string` | A name prefix used for tagging and naming resources created by this module. | `null` | Yes |
| `instance_type` | `string` | shape of instnace| No |
| `min_size` | `number` |  number of instances| `2` | No |
  `max_size` | `number` | number of instances | `5` | No |
| `vpc_id` | `string` | VPC ID where resources (e.g., security groups, subnets) will be created/attached. | `null` | Yes |
| `subnet_ids` | `list(string)` | Subnet IDs used for placing resources (e.g., instances, load balancers). | `[]` | Yes (module-specific) |
| 



---

## Outputs

| Name | Description |
|------|-------------|
| `alb_dns_name` |DNS name of the load balancer |
| `asg_name` | Name of the Auto Scaling Group |



---

## Usage (Minimum Required Inputs)

```hcl
module "webserver_cluster" {

  source = "github.com/tabby123-dev/terraform-aws-webserver-cluster?ref=v0.0.2"
  cluster_name  = "webservers-dev"
  instance_type = "t3.small"
  min_size      = 2
 max_size      = 4
}

output "alb_dns_name" {
  value = module.webserver_cluster.alb_dns_name
}
