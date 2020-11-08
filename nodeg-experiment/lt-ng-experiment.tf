resource "aws_launch_template" "lt-ng-experiment" {
  disable_api_termination = false
  instance_type           = "t3.small"
  key_name                = "eksworkshop"
  name                    = format("at-lt-%s-experiment", data.aws_eks_cluster.mycluster.name)
  tags                    = {}
  image_id                = "ami-0c504dda1302b182f"
  user_data               ="TUlNRS1WZXJzaW9uOiAxLjAKQ29udGVudC1UeXBlOiBtdWx0aXBhcnQvbWl4ZWQ7IGJvdW5kYXJ5PSI9PU1ZQk9VTkRBUlk9PSIKCi0tPT1NWUJPVU5EQVJZPT0KQ29udGVudC1UeXBlOiB0ZXh0L3gtc2hlbGxzY3JpcHQ7IGNoYXJzZXQ9InVzLWFzY2lpIgoKIyEvYmluL2Jhc2gKZWNobyAiUnVubmluZyBjdXN0b20gdXNlciBkYXRhIHNjcmlwdCIKZWNobyAiUnVubmluZyBjdXN0b20gdXNlciBkYXRhIHNjcmlwdCIgPiAvdG1wL21lLnR4dAp5dW0gaW5zdGFsbCAteSBhbWF6b24tc3NtLWFnZW50CmVjaG8gInl1bSdkIGFnZW50IiA+PiAvdG1wL21lLnR4dApzeXN0ZW1jdGwgZW5hYmxlIGFtYXpvbi1zc20tYWdlbnQgJiYgc3lzdGVtY3RsIHN0YXJ0IGFtYXpvbi1zc20tYWdlbnQKZGF0ZSA+PiAvdG1wL21lLnR4dAoKLS09PU1ZQk9VTkRBUlk9PS0t"
  vpc_security_group_ids  = [data.terraform_remote_state.net.outputs.allnodes-sg] 
  tag_specifications { 
    resource_type = "instance"
   tags = {
      Name = format("%s-experiment", data.aws_eks_cluster.mycluster.name)
    }
  }
  lifecycle {
    create_before_destroy=true
  }
}
