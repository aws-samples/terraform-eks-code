resource "aws_launch_template" "lt-ng1" {
  instance_type          = "m6a.large"
  key_name               = data.aws_ssm_parameter.key_name.value
  name                   = format("at-lt-%s-ng1", data.aws_eks_cluster.eks_cluster.name)
  tags                   = {}
  image_id               = data.aws_ssm_parameter.eksami.value
  user_data              = base64encode(local.eks-node-private-userdata)
  vpc_security_group_ids = [data.aws_ssm_parameter.allnodes-sg.value]
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = format("%s-ng1", data.aws_eks_cluster.eks_cluster.name)
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}


# block_device_mappings {
#   device_name = "/dev/sda1"
#
#    ebs {
#      volume_size = 32
#    }
#  }


## Enable this when you use cluster autoscaler within cluster.
## https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md

#  tag {
#    key                 = "k8s.io/cluster-autoscaler/enabled"
#    value               = ""
#    propagate_at_launch = true
#  }
#
#  tag {
#    key                 = "k8s.io/cluster-autoscaler/${var.cluster-name}"
#    value               = ""
#    propagate_at_launch = true
#  }



