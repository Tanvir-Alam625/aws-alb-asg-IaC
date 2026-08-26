variable "project_name" { type = string }
variable "environment" { type = string }
variable "alb_dns_name" { type = string }
variable "repository_url" { type = string }
variable "repository_branch" { type = string }
variable "common_tags" { type = map(string) }
