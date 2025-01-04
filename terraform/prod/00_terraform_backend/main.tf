module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket = "dom24-tfstate"

  versioning = {
    enabled = true
  }
}

resource "aws_dynamodb_table" "terraform_lock" {
  name         = "terraform-lock-table"
  billing_mode = "PAY_PER_REQUEST" # Mode On-Demand
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

