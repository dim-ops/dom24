terraform {
  backend "s3" {
    bucket         = "dom24-tfstate-24"
    key            = "eu-south-2/prod/00_terraform_backend/terraform.tfstate"
    region         = "eu-south-2"
    dynamodb_table = "terraform-lock-table"
  }
  required_version = "~> 1.0"
}

provider "aws" {
  default_tags {
    tags = {
      Environment = "Production"
      Terraform   = "true"
      Project     = "dom24"
    }
  }
}
