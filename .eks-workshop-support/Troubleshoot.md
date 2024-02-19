# prepare environemtn error:


Deleting VPC Lattice routes and gateway...
error: resource mapping not found for name: "checkoutroute" namespace: "checkout" from "/home/ec2-user/environment/eks-workshop/modules/networking/vpc-lattice/routes/checkout-route.yaml": no matches for kind "HTTPRoute" in version "gateway.networking.k8s.io/v1beta1"
ensure CRDs are installed first
An error occurred, please contact your workshop proctor or raise an issue at https://github.com/aws-samples/eks-workshop-v2/issues

fix:

cd /eks-workshop/terraform
terraform destroy

cd  /eks-workshop/hooks
try manually running commands

then

rm -rf cd  /eks-workshop/hooks