sed -i'.orig' -e 's/cluster_endpoint_public_access = false/cluster_endpoint_public_access = true/' main.tf
terraform apply -auto-approve