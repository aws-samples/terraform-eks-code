sed -i'.orig' -e 's/cluster_endpoint_public_access = true/cluster_endpoint_public_access = false/' main.tf
terraform apply -auto-approve