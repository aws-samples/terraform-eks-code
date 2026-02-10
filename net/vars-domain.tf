# Domain Name Variable
# Used for Route53 private hosted zone creation
# Combined with account ID and random ID to create unique zone name

# Alternative domain for testing
#variable "dn" {
#  type    = string
#  default = "testdomain.local"
#}

# Production domain name
variable "dn" {
  type    = string
  default = "people.aws.dev"
}
