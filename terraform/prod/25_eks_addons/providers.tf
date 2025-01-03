terraform {
  backend "s3" {
    bucket         = "dom24-tfstate"
    key            = "eu-south-2/prod/25_eks_addons/terraform.tfstate"
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

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "dom24-prod"
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "dom24-prod"
}


