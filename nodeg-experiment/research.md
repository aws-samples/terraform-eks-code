data "template_file" "eks_node_userdata" {
  template = "${file("${path.module}/user-data.sh")}"

  vars {
      kubeconfig_cert_auth_data = "fill in the blanks"
      cluster_endpoint          = "fill in the blanks"
      cluster_name              = "${var.eks_cluster_name}"
      node_label                = "${lookup(var.worker_launch_config_lst[count.index], "kubelet_extra_args", local.worker_lt_defaults["kubelet_extra_args"])}"
      node_taint                = "${lookup(var.worker_launch_config_lst[count.index], "node_taint", "")}"
      ami_id                    = "${lookup(var.worker_launch_config_lst[count.index], "eks_ami_id", local.worker_lt_defaults["eks_ami_id"])}"
      instance_type             = "${lookup(var.worker_launch_config_lst[count.index], "instance_type", "")}"
      docker_config_json        = "${jsonencode(lookup(var.worker_launch_config_lst[count.index], "docker_config_json", ""))}"
  }
}

#!/bin/bash -xe

/etc/eks/bootstrap.sh --use-max-pods true --b64-cluster-ca ${kubeconfig_cert_auth_data} \
--apiserver-endpoint ${cluster_endpoint} ${cluster_name} \
--kubelet-extra-args '--register-with-taints="${node_taint}" --node-labels="${node_label},ami_id=${ami_id},instance_type=${instance_type}"' --docker-config-json ${docker_config_json}



5059   18514 kubelet.go:2273] node "ip-192-168-131-208.eu-west-1.compute.internal" not found
Nov 08 18:33:30 ip-192-168-131-208.eu-west-1.compute.internal kubelet[18514]: W1108 18:33:30.843743   18514 cni.go:237] Unable to update cni config: no networks found in /etc/cni/net.d

Adding on re: tags, the typo is a newb mistake. Digging for more complicated reasons was rough. Node has to be 'owned' by a certain cluster. The nodes will only join a cluster its supposed to. I overlooked this but there was not a lot of docs on it. In my case using terraform. Make sure variables match. This is node tag naming parent cluster to join

  tag {
    key = "kubernetes.io/cluster/${var.eks_cluster_name}-${terraform.workspace}"
    value = "owned"
    propagate_at_launch = true
  }


  