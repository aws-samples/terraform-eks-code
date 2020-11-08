of="lt-ng-experiment.tf"
ami=`aws ssm get-parameter --name /aws/service/eks/optimized-ami/1.17/amazon-linux-2/recommended/image_id --region eu-west-1 --query "Parameter.Value" --output text`
b64=`cat user_data.sh | openssl enc -A -base64`

printf "" > $of
printf "resource \"aws_launch_template\" \"lt-ng-experiment\" {\n" >> $of
printf "  depends_on = [null_resource.gen_lt]" >> $of
printf "  disable_api_termination = false\n" >> $of
printf "  instance_type           = \"t3.small\"\n" >> $of
printf "  key_name                = \"eksworkshop\"\n" >> $of
echo '  name                    = format("at-lt-%s-experiment", data.aws_eks_cluster.mycluster.name)' >> $of
printf "  tags                    = {}\n" >> $of
printf "  image_id                = \"%s\"\n" $ami >> $of

printf "  user_data               =\"%s\"\n" $b64 >> $of
printf "  vpc_security_group_ids  = [data.terraform_remote_state.net.outputs.allnodes-sg] \n" >> $of
printf "  tag_specifications { \n" >> $of
printf "    resource_type = \"instance\"\n" >> $of

printf "   tags = {\n" >> $of
echo '      Name = format("%s-experiment", data.aws_eks_cluster.mycluster.name)' >> $of
printf "    }\n" >> $of
printf "  }\n" >> $of


printf "  lifecycle {\n" >> $of
printf "    create_before_destroy=true\n" >> $of
printf "  }\n" >> $of
printf "}\n" >> $of