terraform {
  required_version = ">= 1.5.7"
  backend "s3" {
    bucket = "2u-terraform-devops-sandbox"
    key    = "cdunda/port-demo/s3-buckets/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.region

  assume_role {
    role_arn = "arn:aws:iam::516590517042:role/OrganizationAccountAccessRole"
  }

  # Make it faster by skipping something
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
}

module "simple_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.1"

  bucket        = var.bucket_name
  force_destroy = true
}
