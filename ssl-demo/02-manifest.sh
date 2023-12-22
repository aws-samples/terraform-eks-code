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