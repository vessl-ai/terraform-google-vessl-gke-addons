locals {
  // https://github.com/cert-manager/cert-manager/blob/master/deploy/charts/cert-manager/values.yaml
  cert_manager_helm_values = {
    affinity = {
      nodeAffinity = local.node_affinity
    }
    tolerations = local.tolerations
  }
}

data "kubectl_path_documents" "cert_manager_crds" {
  pattern = "${path.module}/files/cert-manager/${var.cert_manager.version}.crds.yaml"
}

resource "kubectl_manifest" "cert_manager_crds" {
  count     = var.cert_manager != null ? length(data.kubectl_path_documents.cert_manager_crds.0.documents) : 0
  yaml_body = element(data.kubectl_path_documents.cert_manager_crds.0.documents, count.index)
}

resource "helm_release" "cert_manager" {
  count      = var.cert_manager != null ? 1 : 0
  depends_on = [kubectl_manifest.cert_manager_crds]

  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  name       = "cert-manager"
  namespace  = "kube-system"
  version    = var.cert_manager.version
  values     = [yamlencode(merge(local.cert_manager_helm_values, var.cert_manager.helm_values))]
}
