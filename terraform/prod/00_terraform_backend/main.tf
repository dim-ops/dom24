module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "dom24-tfstate-24"

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

