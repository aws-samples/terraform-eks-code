## Kubecost

WSParticipantRole:~ $ prepare-environment observability/kubecost
Refreshing copy of workshop repository from GitHub...

Resetting the environment...
Tip: Read the rest of the lab introduction while you wait!
Waiting for application to become ready...
Cleaning up previous lab infrastructure...
Creating infrastructure for next lab...
╷
│ Error: creating EKS Add-On (mycluster1:aws-ebs-csi-driver): operation error EKS: CreateAddon, https response error StatusCode: 409, RequestID: 825d65e7-8cf7-4253-bb2b-d7b3c450eea1, ResourceInUseException: Addon already exists.
│ 
│   with module.eks_blueprints_addons.aws_eks_addon.this["aws-ebs-csi-driver"],
│   on .terraform/modules/eks_blueprints_addons/main.tf line 2177, in resource "aws_eks_addon" "this":
│ 2177: resource "aws_eks_addon" "this" {
│ 
╵
An error occurred, please contact your workshop proctor or raise an issue at https://github.com/aws-samples/eks-workshop-v2/issues
The full log can be found here: /eks-workshop/logs/action-1708373796.log

## 