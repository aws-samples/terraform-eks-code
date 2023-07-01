resource "null_resource" "cidr" {
triggers = {
    always_run = timestamp()
}
provisioner "local-exec" {
    on_failure  = fail
    when = create
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
        az1=$(echo ${data.aws_subnet.i1.availability_zone})
        az2=$(echo ${data.aws_subnet.i2.availability_zone})
        az3=$(echo ${data.aws_subnet.i3.availability_zone})
        sub1=$(echo ${data.aws_subnet.i1.id})
        sub2=$(echo ${data.aws_subnet.i2.id})
        sub3=$(echo ${data.aws_subnet.i3.id})
        cn=$(echo ${data.aws_eks_cluster.eks_cluster.name})
        echo $az1 $az2 $az3 $sub1 $sub2 $sub3 $cn
        echo -e "\x1B[35mCycle nodes for custom CNI setting (takes a few minutes) ......\x1B[0m"
        ./cni-cycle-nodes.sh $cn
        echo -e "\x1B[33mAnnotate nodes ......\x1B[0m"
        ./annotate-nodes.sh $az1 $az2 $az3 $sub1 $sub2 $sub3 $cn
        echo -e "\x1B[32mShould see coredns on 100.64.x.y addresses ......\x1B[0m"
        echo -e "\x1B[32mkubectl get pods -A -o wide | grep coredns\x1B[0m"   
     EOT
}
}