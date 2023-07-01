kubectl create deployment demo-app --image=$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/aws/nginx/nginx -n fargate1
kubectl create deployment demo-app --image=public.ecr.aws/nginx/nginx -n fargate1