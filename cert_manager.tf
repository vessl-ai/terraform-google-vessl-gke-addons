locals {
  // https://github.com/cert-manager/cert-manager/blob/master/deploy/charts/cert-manager/values.yaml
  cert_manager_helm_values = {
    affinity = {
      nodeAffinity = local.node_affinity
    }
    tolerations = local.tolerations
  }
}

data "http" "cert_manager_crds" {
  count = var.cert_manager != null ? 1 : 0

  url = "https://github.com/cert-manager/cert-manager/releases/download/${var.cert_manager.version}/cert-manager.crds.yaml"
}

resource "kubectl_manifest" "cert_manager_crds" {
  count = var.cert_manager != null ? 1 : 0

  yaml_body = data.http.cert_manager_crds.0.response_body
}

resource "helm_release" "cert_manager" {
  count      = var.cert_manager != null ? 1 : 0
  depends_on = [kubectl_manifest.cert_manager_crds]

  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  name       = "cert-manager"
  version    = var.cert_manager.version
  values     = [yamlencode(merge(local.cert_manager_helm_values, var.cert_manager.helm_values))]
}
