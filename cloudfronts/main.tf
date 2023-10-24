terraform {
  required_version = ">= 1.5.7"
  backend "s3" {
    bucket   = "2u-terraform-devops-sandbox"
    key      = "cdunda/port-demo/cloudfronts/terraform.tfstate"
    region   = "us-east-1"
    role_arn = "arn:aws:iam::516590517042:role/OrganizationAccountAccessRole"
  }
}

provider "aws" {
  region = var.region

  assume_role {
    role_arn = "arn:aws:iam::516590517042:role/OrganizationAccountAccessRole"
  }

  # Make it faster by skipping something
  skip_metadata_api_check = true
  skip_region_validation  = true
}


provider "aws" {
  alias  = "usw2"
  region = "us-west-2"

  assume_role {
    role_arn = "arn:aws:iam::516590517042:role/OrganizationAccountAccessRole"
  }

  # Make it faster by skipping something
  skip_metadata_api_check = true
  skip_region_validation  = true
}
