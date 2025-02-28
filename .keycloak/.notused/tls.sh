openssl req -new -x509 -sha256 -nodes -newkey rsa:4096 -keyout private_keycloak.key -out certificate_keycloak.crt -subj "/CN=keycloak.local"
aws acm import-certificate --certificate fileb://certificate_keycloak.crt --private-key fileb://private_keycloak.key
aws acm list-certificates --include keyTypes=RSA_4096
cat << 'EoF' >> manifest-template.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: keycloak-ingress
  namespace: myapplications-ns
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/group.name: frontend
    alb.ingress.kubernetes.io/certificate-arn: ${ACM_ARN}
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS": 443}]'
  labels:
    app: ${CURRET_PET}-ingress
spec:
  ingressClassName: alb
  rules:
    - host: ${CURRET_PET}.local
      http:
        paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: ${CURRET_PET}-service
              port:
                number: 80

---
apiVersion: v1
kind: Pod
metadata:
  name: ${CURRET_PET}
  namespace: myapplications-ns
  labels:
    app.kubernetes.io/name: ${CURRET_PET}-proxy
spec:
  containers:
  - name: nginx
    image: nginx:stable
    ports:
      - containerPort: 80
        name: ${CURRET_PET}podsvc
    volumeMounts:
    - name: index-nginx
      mountPath: /usr/share/nginx/html/
  volumes:
  - name: index-nginx
    configMap:
      name: configmap-${CURRET_PET}
---
apiVersion: v1
kind: Service
metadata:
  name: ${CURRET_PET}-service
  namespace: myapplications-ns
spec:
  selector:
    app.kubernetes.io/name: ${CURRET_PET}-proxy
  ports:
  - name: name-of-service-port
    protocol: TCP
    port: 80
    targetPort: ${CURRET_PET}podsvc

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: configmap-${CURRET_PET}
  namespace: myapplications-ns
data:
  index.html: |
    <html>
      <body>
        <h1>Welcome to ${CURRET_PET}.local! </h1>
      </body>
    </html>
EoF

export CURRET_PET=keycloak
export ACM_ARN=$(aws acm list-certificates --query "CertificateSummaryList[?DomainName=='keycloak.local'].CertificateArn" --include keyTypes=RSA_4096 --output text)
envsubst < "manifest-template.yaml" > "keycloak.yaml"

aws route53 create-hosted-zone --name keycloak.local \
--caller-reference my-private-zone\
--hosted-zone-config Comment=”my private zone”,PrivateZone=true \
--vpc VPCRegion=us-east-1,VPCId=<VPC-ID>

aws route53 change-resource-record-sets --hosted-zone-id <Private-hosted-zone-id> --change-batch \ '{"Changes": [ { "Action": "CREATE", "ResourceRecordSet": { "Name": "keycloak.local", "Type": "A", "AliasTarget":{ "HostedZoneId": "<zone-id-of-ALB>","DNSName": "<DNS-of-ALB>",","EvaluateTargetHealth": false} } } ]}'
