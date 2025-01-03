terraform {
  backend "s3" {
    bucket         = "dom24-tfstate"
    key            = "eu-south-2/prod/20_eks/terraform.tfstate"
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
