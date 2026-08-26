output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_app_subnet_ids" {
  value = module.vpc.private_app_subnet_ids
}

output "private_database_subnet_ids" {
  value = module.vpc.private_database_subnet_ids
}

output "bastion_public_ip" {
  value = module.bastion.bastion_public_ip
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "database_private_ip" {
  value = module.database.private_ip
}

output "asg_name" {
  value = module.autoscaling.asg_name
}
