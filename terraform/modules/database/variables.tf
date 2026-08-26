variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_id" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "key_name" {
  type = string
}

variable "database_name" {
  type = string
}

variable "database_user" {
  type = string
}

variable "database_password" {
  type = string
}

variable "database_volume_size" {
  type = number
}

variable "common_tags" {
  type = map(string)
}

variable "availability_zone" {
  type    = string
  default = "ap-south-1a"
}
