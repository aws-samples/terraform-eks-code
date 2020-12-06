resource "aws_dynamodb_table" "terraform_locks_net" {
  depends_on=[aws_s3_bucket.terraform_state]
  name         = var.table_name_net
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_dynamodb_table" "terraform_locks_iam" {
  name         = var.table_name_iam
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_dynamodb_table" "terraform_locks_c9net" {
  name         = var.table_name_c9net
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_dynamodb_table" "terraform_locks_cluster" {
  name         = var.table_name_cluster
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}


resource "aws_dynamodb_table" "terraform_locks_nodeg" {
  depends_on = [aws_dynamodb_table.terraform_locks_net]
  name         = var.table_name_nodeg
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_dynamodb_table" "terraform_locks_cicd" {
  name         = var.table_name_cicd
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_dynamodb_table" "terraform_locks_eks-cidr" {
  depends_on = [aws_dynamodb_table.terraform_locks_net]
  name         = var.table_name_eks-cidr
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}