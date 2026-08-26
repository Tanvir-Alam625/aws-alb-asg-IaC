terraform {
  backend "s3" {
    # Terraform backend values must be literal; they cannot use var.* references.
    bucket  = "tv-aws-iac-full-infrasture-state"
    key     = "prod/terraform.tfstate"
    region  = "ap-south-1"
    profile = "tv-ostad-aws"
    encrypt = true
  }
}