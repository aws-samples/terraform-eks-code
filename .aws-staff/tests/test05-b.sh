echo -n 'KEYID' > ./access-key
echo -n 'SECRETKEY' > ./secret-access-key
kubectl create namespace test-ext-secret
kubectl -n test-ext-secret create secret generic awssm-secret --from-file=./access-key --from-file=./secret-access-key
cat << EOF | kubectl apply -f -
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: secretstore-sample
  namespace: test-ext-secret
spec:
  provider:
    aws:
      service: SecretsManager
      region: eu-west-1
      auth:
        secretRef:
          accessKeyIDSecretRef:
            name: awssm-secret
            key: access-key
          secretAccessKeySecretRef:
            name: awssm-secret
            key: secret-access-key
EOF
