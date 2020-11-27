resource "null_resource" "cidr" {
triggers = {
    always_run = "${timestamp()}"
}
provisioner "local-exec" {
    on_failure  = fail
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
        echo -e "\x1B[31m Warning! ${data.aws_subnet.i1.availability_zone}\x1B[0m"
        echo -e "\x1B[31m Warning! ${data.aws_subnet.i1.id}\x1B[0m"
        az1=$(echo ${data.aws_subnet.i1.availability_zone})
        echo $az1
        echo "************************************************************************************"
     EOT
}
}