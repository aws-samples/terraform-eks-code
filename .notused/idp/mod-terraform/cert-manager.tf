#resource "kubectl_manifest" "application_argocd_cert_manager" {
#  yaml_body = templatefile("${path.module}/templates/argocd-apps/cert-manager.yaml", {
#    REPO_URL = local.repo_url
#  })

#  provisioner "local-exec" {
#    command = "kubectl wait --for=jsonpath=.status.health.status=Healthy -n argocd application/cert-manager && kubectl wait --for=jsonpath=.status.sync.status=Synced --timeout=300s -n argocd application/cert-manager && sleep 60"
#
#    interpreter = ["/bin/bash", "-c"]
#  }
#}

resource "kubectl_manifest" "cluster_issuer_prod" {
  depends_on = [ 
    #kubectl_manifest.application_argocd_cert_manager,
    kubectl_manifest.application_argocd_ingress_nginx
  ]
  yaml_body = templatefile("${path.module}/templates/manifests/cluster-issuer.yaml", {
    REPO_URL = local.repo_url
  })
}