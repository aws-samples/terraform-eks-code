References

https://github.com/cnoe-io/reference-implementation-aws
https://cnoe.io/docs/reference-implementation/installations

https://github.com/cnoe-io/cnoe-cli

https://github.com/cnoe-io/idpbuilder
(uses gitea - standalone git !)




checks:
kubectl get pods -n cert-manager | grep Running | wc -l 
(should be 3)
kubectl -n argo get certificate
(shoud return True) - comes from letsencypt (not ACM)

------

## ArgoCD

kubectl port-forward svc/argocd-server -n argocd 8081:80
Go to http://localhost:8081

ArgoCD - admin/pw
Pw:
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
(if % on end - don't paste that)



## Keycloak

keycloak.demo.awsandy.people.aws.dev
(not directly available)

-------

## Backstage

backstage.demo.awsandy.people.aws.dev

username: user1
kubectl get secrets -n keycloak keycloak-user-config -o go-template='{{range $k,$v := .data}}{{printf "%s: " $k}}{{if not $v}}{{$v}}{{else}}{{$v | base64decode}}{{end}}{{"\n"}}{{end}}'

kubectl get secrets -n keycloak keycloak-user-config -o json | jq  -r '.data."user1-password"' | base64 -d