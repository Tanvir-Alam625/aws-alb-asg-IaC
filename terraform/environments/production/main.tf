locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

module "vpc" {
  source = "../../modules/vpc"

  project_name                  = var.project_name
  environment                   = var.environment
  vpc_cidr                      = var.vpc_cidr
  availability_zones            = var.availability_zones
  public_subnet_cidrs           = var.public_subnet_cidrs
  private_app_subnet_cidrs      = var.private_app_subnet_cidrs
  private_database_subnet_cidrs = var.private_database_subnet_cidrs
  enable_multi_nat_gateway      = var.enable_multi_nat_gateway
  common_tags                   = local.common_tags
}

module "security_groups" {
  source = "../../modules/security-groups"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  admin_cidr   = var.admin_cidr
  backend_port = var.backend_port
  common_tags  = local.common_tags
}

module "database" {
  source = "../../modules/database"

  project_name = var.project_name
  environment  = var.environment

  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.private_database_subnet_ids
  security_group_id    = module.security_groups.database_security_group_id
  ami_id               = var.database_ami_id != "" ? var.database_ami_id : data.aws_ami.ubuntu.id
  instance_type        = var.database_instance_type
  key_name             = var.key_name
  database_name        = var.database_name
  database_user        = var.database_user
  database_password    = var.database_password
  database_volume_size = 20
  common_tags          = local.common_tags
}

module "bastion" {
  source = "../../modules/bastion"

  project_name       = var.project_name
  environment        = var.environment
  subnet_id          = module.vpc.public_subnet_ids[0]
  security_group_id  = module.security_groups.bastion_security_group_id
  key_name           = var.key_name
  ami_id             = var.backend_ami_id != "" ? var.backend_ami_id : data.aws_ami.ubuntu.id
  instance_type      = var.backend_instance_type
  common_tags        = local.common_tags
}

module "alb" {
  source = "../../modules/alb"

  project_name              = var.project_name
  environment               = var.environment
  vpc_id                    = module.vpc.vpc_id
  subnets                   = module.vpc.public_subnet_ids
  security_group_id         = module.security_groups.alb_security_group_id
  backend_target_group_name = "${var.project_name}-${var.environment}-backend-tg"
  backend_port              = var.backend_port
  enable_https              = var.enable_https
  acm_certificate_arn       = var.acm_certificate_arn
  common_tags               = local.common_tags
}

module "launch_template" {
  source = "../../modules/launch-template"

  project_name      = var.project_name
  environment       = var.environment
  ami_id            = var.backend_ami_id != "" ? var.backend_ami_id : data.aws_ami.ubuntu.id
  instance_type     = var.backend_instance_type
  key_name          = var.key_name
  security_group_id = module.security_groups.backend_security_group_id
  root_volume_size  = 20
  user_data = templatefile("../../scripts/backend-user-data.sh", {
    repo_url                = var.repository_url
    repo_branch             = var.repository_branch
    app_port                = var.app_port
    db_host                 = module.database.private_ip
    db_name                 = var.database_name
    db_user                 = var.database_user
    db_password             = var.database_password
    environment             = var.environment
    project_name            = var.project_name
    domain_name             = var.app_domain_name
    database_name           = var.database_name
    database_user           = var.database_user
    database_password       = var.database_password
    cloudflare_cert_content = file("/home/devtanvir01/projects/devops/aws-iac-with-alb/tanvirops.xyz.crt")
    cloudflare_key_content  = file("/home/devtanvir01/projects/devops/aws-iac-with-alb/tanvirops.xyz.key")
  })
  common_tags = local.common_tags
}

module "autoscaling" {
  source = "../../modules/autoscaling"

  project_name            = var.project_name
  environment             = var.environment
  launch_template_id      = module.launch_template.launch_template_id
  launch_template_version = module.launch_template.launch_template_version
  subnets                 = module.vpc.private_app_subnet_ids
  target_group_arn        = module.alb.target_group_arn
  min_size                = var.asg_min_size
  desired_capacity        = var.asg_desired_size
  max_size                = var.asg_max_size
  target_cpu_utilization  = var.target_cpu_utilization
  common_tags             = local.common_tags
}

module "monitoring" {
  source = "../../modules/monitoring"

  project_name   = var.project_name
  environment    = var.environment
  alb_arn_suffix = module.alb.alb_arn_suffix
  asg_name       = module.autoscaling.asg_name
  common_tags    = local.common_tags
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
