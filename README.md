# AWS 3-Tier ALB + ASG + PostgreSQL EC2 + Bastion + GitHub Actions

This repository contains a production-style Terraform implementation for a 3-tier AWS architecture using:

- VPC with public and private subnets
- Internet-facing Application Load Balancer
- Private backend EC2 instances behind an Auto Scaling Group
- Dedicated PostgreSQL EC2 instance in a private subnet
- Bastion host for SSH access
- Remote Terraform state in S3 with locking
- GitHub Actions deploy workflow for the main branch

## Terraform backend bootstrap

Before running Terraform for production, create the S3 backend bucket and DynamoDB lock table:

```bash
aws sts get-caller-identity --profile tv-ostad-aws --region ap-south-1
```

Then create the bucket with Terraform or AWS CLI. This project expects:

- Region: ap-south-1
- Profile: tv-ostad-aws
- State bucket: tv-aws-iac-full-infrasture-state
- State key: prod/terraform.tfstate

## Terraform commands

```bash
cd terraform/environments/production
terraform init
terraform validate
terraform plan
terraform apply
```

## Project structure

```text
aws-with-alb-asg-3-tier-iac/
├── README.md
├── DEPLOYMENT.md
├── ARCHITECTURE.md
├── .github/
│   └── workflows/
│       └── deploy-production.yml
├── appspec.yml
├── terraform/
│   ├── environments/
│   │   └── production/
│   │       ├── backend.tf
│   │       ├── providers.tf
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       ├── outputs.tf
│   │       └── terraform.tfvars.example
│   ├── modules/
│   │   ├── vpc/
│   │   ├── security-groups/
│   │   ├── alb/
│   │   ├── bastion/
│   │   ├── database/
│   │   ├── launch-template/
│   │   ├── autoscaling/
│   │   ├── monitoring/
│   │   └── deployment/
│   └── scripts/
│       ├── backend-user-data.sh
│       └── database-user-data.sh
└── .gitignore
```

## Notes

- This implementation keeps PostgreSQL on a dedicated EC2 instance instead of RDS, as required.
- Sensitive values such as DB passwords should not be committed to Git.
- The project is designed to be extended for blue/green or rolling deployment tooling as needed.
