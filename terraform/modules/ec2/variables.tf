variable "project_name" { type = string }
variable "environment" { type = string }
variable "vpc_id" { type = string }
variable "app_subnet_ids" { type = list(string) }
variable "alb_security_group_id" { type = string }
variable "target_group_arn" { type = string }
variable "iam_instance_profile" { type = string }
variable "instance_type" { type = string }
variable "ami_id" { type = string }
variable "db_endpoint" { type = string }
variable "db_name" { type = string }
variable "db_username" { type = string }
variable "s3_bucket_name" { type = string }
variable "min_size" { type = number; default = 2 }
variable "max_size" { type = number; default = 6 }
variable "desired_capacity" { type = number; default = 2 }
