terraform {
  backend "s3" {
    bucket         = "dom24-tfstate"
    key            = "eu-south-2/prod/30_waf/terraform.tfstate"
    region         = "eu-south-2"
    dynamodb_table = "terraform-lock-table"
  }
  required_version = "~> 1.0"
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "dom24-prod"
}
