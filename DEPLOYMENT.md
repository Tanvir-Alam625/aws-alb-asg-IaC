# Deployment Guide

## Prerequisites

1. AWS CLI configured with the `tv-ostad-aws` profile.
2. Terraform `>= 1.9.0` installed.
3. Existing EC2 key pair `tv_key` in `ap-south-1`.
4. S3 backend bucket created before the first `terraform init`.

## Backend bootstrap

```bash
aws sts get-caller-identity --profile tv-ostad-aws --region ap-south-1
```

Create the S3 bucket and DynamoDB lock table using a separate bootstrap step before enabling remote state.

## Production deployment

```bash
cd terraform/environments/production
terraform init
terraform validate
terraform plan
terraform apply
```

## Verify infrastructure

```bash
terraform output
curl http://$(terraform output -raw alb_dns_name)/health
ssh -J ubuntu@$(terraform output -raw bastion_public_ip) ubuntu@<private-backend-ip>
```

## IAM and security considerations

- SSH access is allowed only from `admin_cidr`.
- ALB is internet-facing; backend and database are private.
- No direct public access to PostgreSQL or backend EC2 is permitted.
- Application deploys through GitHub Actions and CodeDeploy or equivalent deployment automation.

## Rollback

1. Revert the GitHub push or redeploy the previous artifact.
2. Re-run the deployment workflow against the previous application revision.
3. Confirm ALB health checks return healthy before traffic is switched back.
