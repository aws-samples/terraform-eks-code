resource "aws_launch_template" "lt-ng2" {
  #instance_type           = "m5a.large"
  key_name               = data.aws_ssm_parameter.key_name.value
  name                   = format("at-lt-%s-ng2", data.aws_eks_cluster.eks_cluster.name)
  tags                   = {}
  image_id               = data.aws_ssm_parameter.eksami.value
  user_data              = base64encode(local.eks-node-private-userdata)
  vpc_security_group_ids = [data.aws_ssm_parameter.allnodes-sg.value]
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = format("%s-ng2", data.aws_eks_cluster.eks_cluster.name)
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}

