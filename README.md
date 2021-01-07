# Terraform-EKS
Sub directories contain the workshop content
- setup-tools.sh installs local tooling for workshop
- resize-osdisk.sh resizes local OS disk to 30GB (if staging larger docker images etc)
  
- build-everything.sh - will build all the terraform 7x stages in the workshop
- destroy-everything.sh will attempt to tear down everything (needs work for ingress/load balancers)  