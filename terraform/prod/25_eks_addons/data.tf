data "aws_region" "current" {}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "dom24-tfstate-24"
    key    = "eu-south-2/prod/10_vpc/terraform.tfstate"
    region = "eu-south-2"
  }
}

data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "dom24-tfstate-24"
    key    = "eu-south-2/prod/20_eks/terraform.tfstate"
    region = "eu-south-2"
  }
}
