sed -i'.orig' -e 's/\(endpoint_public_access *= *\)true/\1false/' main.tf
terraform apply -auto-approve