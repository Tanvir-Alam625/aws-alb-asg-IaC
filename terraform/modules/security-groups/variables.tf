variable "project_name" { type = string }
variable "environment" { type = string }
variable "vpc_id" { type = string }
variable "admin_cidr" { type = string }
variable "backend_port" { type = number }
variable "common_tags" { type = map(string) }
