variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_app_subnet_cidrs" {
  type = list(string)
}

variable "private_database_subnet_cidrs" {
  type = list(string)
}

variable "enable_multi_nat_gateway" {
  type = bool
}

variable "common_tags" {
  type = map(string)
}
