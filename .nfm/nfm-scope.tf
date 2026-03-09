resource "aws_networkflowmonitor_scope" "example" {
  target {
    region = data.aws_region.current.region
    target_identifier {
      target_type = "ACCOUNT"
      target_id {
        account_id = data.aws_caller_identity.current.account_id
      }
    }
  }

  tags = {
    Name = "example"
  }
}