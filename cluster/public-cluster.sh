sed -i'.orig' -e 's/\(endpoint_public_access *= *\)false/\1true/' main.tf
terraform apply -auto-approve