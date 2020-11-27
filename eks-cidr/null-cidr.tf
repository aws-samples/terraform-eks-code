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
        az2=$(echo ${data.aws_subnet.i2.availability_zone})
        az3=$(echo ${data.aws_subnet.i3.availability_zone})
        sub1=$(echo ${data.aws_subnet.i1.id})
        sub2=$(echo ${data.aws_subnet.i2.id})
        sub3=$(echo ${data.aws_subnet.i3.id})
        echo $az1 $az2 $az3 $sub1 $sub2 $sub3
        echo "************************************************************************************"
     EOT
}
}