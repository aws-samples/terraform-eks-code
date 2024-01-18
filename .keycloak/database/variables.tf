variable "db_password" {
  type        = string
  description = "DB administrator password"
  sensitive   = true
  default = "keycloakpass123"
}

variable "db_username" {
  type        = string
  description = "DB username"
  default = "admin"
}

variable "database_name" {
  type        = string
  description = "DB Name"
  default = "keycloak"
}

#variable "cluster_sg_id" {
#  type        = string
#  description = "EKS Cluster SG ID"
#}

#variable "vpc_id" {
#  type        = string
#  description = "Keycloak VPC ID from the EKS module"
#}

#variable "database_subnets" {
#  type        = list
#  description = "Keycloak VPC database subnets"
#}

#variable "database_subnets_cidr_blocks" {
#  type        = list
#  description = "Keycloak VPC cidr_blocks of database subnets"
#}