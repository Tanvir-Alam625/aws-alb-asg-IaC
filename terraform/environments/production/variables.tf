variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "ap-south-1"
}

variable "aws_profile" {
  description = "AWS CLI profile used for deployment"
  type        = string
  default     = "tv-ostad-aws"
}

variable "terraform_state_bucket" {
  description = "S3 bucket used for Terraform remote state"
  type        = string
  default     = "tv-aws-iac-full-infrasture-state"
}

variable "terraform_state_key" {
  description = "S3 key used for Terraform remote state"
  type        = string
  default     = "prod/terraform.tfstate"
}

variable "terraform_state_region" {
  description = "AWS region for Terraform remote state bucket"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project prefix used in resource names"
  type        = string
  default     = "tv-3tier"
}

variable "environment" {
  description = "Deployment environment label"
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones for the VPC and subnets"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for private application subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "private_database_subnet_cidrs" {
  description = "CIDR blocks for private database subnets"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]
}

variable "admin_cidr" {
  description = "CIDR allowed to reach bastion SSH"
  type        = string
  default     = "0.0.0.0/0"
}

variable "key_name" {
  description = "Existing EC2 key pair name"
  type        = string
  default     = "tv_key"
}

variable "backend_ami_id" {
  description = "AMI ID for backend EC2 instances"
  type        = string
  default     = ""
}

variable "backend_instance_type" {
  description = "Instance type for backend EC2 autoscaling"
  type        = string
  default     = "t3.micro"
}

variable "database_ami_id" {
  description = "AMI ID for PostgreSQL EC2 instance"
  type        = string
  default     = ""
}

variable "database_instance_type" {
  description = "Instance type for database EC2"
  type        = string
  default     = "t3.micro"
}

variable "database_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "bmi_health"
  sensitive   = true
}

variable "database_user" {
  description = "PostgreSQL database user"
  type        = string
  default     = "bmi_user"
  sensitive   = true
}

variable "database_password" {
  description = "PostgreSQL password"
  type        = string
  default     = "StrongPassword123!"
  sensitive   = true

  validation {
    condition     = length(trimspace(var.database_password)) >= 12
    error_message = "database_password must be set to a value at least 12 characters long. Prefer passing it via tfvars or environment variables, not source control."
  }
}

variable "backend_port" {
  description = "Port exposed by the EC2 host to the ALB (nginx listener)"
  type        = number
  default     = 80
}

variable "app_port" {
  description = "Port used by the Node.js backend application behind nginx"
  type        = number
  default     = 3000
}

variable "asg_min_size" {
  description = "Minimum ASG size"
  type        = number
  default     = 1
}

variable "asg_desired_size" {
  description = "Desired ASG size"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Maximum ASG size"
  type        = number
  default     = 3
}

variable "target_cpu_utilization" {
  description = "CPU target used for ASG scaling policy"
  type        = number
  default     = 50
}

variable "repository_url" {
  description = "Git repository URL used by application deployment"
  type        = string
  default     = "https://github.com/Tanvir-Alam625/bmi-health-tracker-ec2-server.git"
}

variable "repository_branch" {
  description = "Production repository branch"
  type        = string
  default     = "main"
}

variable "enable_multi_nat_gateway" {
  description = "Create one NAT gateway per AZ for HA"
  type        = bool
  default     = true
}

variable "app_domain_name" {
  description = "Public hostname used for the application domain"
  type        = string
  default     = "3tier.tanvirops.xyz"
}

variable "enable_https" {
  description = "Creates HTTPS ALB listener when ACM cert is available"
  type        = bool
  default     = true
}

variable "acm_certificate_arn" {
  description = "Optional ACM certificate ARN for HTTPS listener"
  type        = string
  default     = ""
}
