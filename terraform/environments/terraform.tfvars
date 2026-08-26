aws_region  = "ap-south-1"
aws_profile = "tv-ostad-aws"

terraform_state_bucket = "tv-aws-iac-full-infrasture-state"
terraform_state_key    = "prod/terraform.tfstate"
terraform_state_region = "ap-south-1"

project_name = "tv-3tier"
environment  = "prod"

vpc_cidr = "10.0.0.0/16"

availability_zones = ["ap-south-1a", "ap-south-1b"]

public_subnet_cidrs       = ["10.0.1.0/24", "10.0.2.0/24"]
private_app_subnet_cidrs  = ["10.0.11.0/24", "10.0.12.0/24"]
private_database_subnet_cidrs = ["10.0.21.0/24", "10.0.22.0/24"]

admin_cidr = "0.0.0.0/0"
key_name   = "tv_key"

backend_ami_id        = ""
database_ami_id       = ""
backend_instance_type = "t3.micro"
database_instance_type = "t3.micro"

backend_port = 80
app_port     = 3000

asg_min_size     = 1
asg_desired_size = 1
asg_max_size     = 3
target_cpu_utilization = 50

repository_url    = "https://github.com/Tanvir-Alam625/bmi-health-tracker-ec2-server.git"
repository_branch = "main"

enable_multi_nat_gateway = true
enable_https              = true
acm_certificate_arn       = ""
app_domain_name           = "3tier.tanvirops.xyz"

database_name = "bmi_health"
database_user = "bmi_user"
database_password = "StrongPassword123!"
