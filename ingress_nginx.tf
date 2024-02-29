locals {
  // https://github.com/kubernetes/ingress-nginx/blob/main/charts/ingress-nginx/values.yaml
  ingress_nginx_helm_values = {
    controller = {
      service = {
        targetPorts = {
          http  = "http",
          https = try(var.ingress_nginx.ssl_termination, false) ? "http" : "https",
        },
        annotations = var.ingress_nginx.service_annotations,
      }
      admissionWebhooks = {
        patch = {
          tolerations = local.tolerations
          nodeSelector = merge(
            { for expression in var.node_affinity : expression.key => expression.values[0] },
            { "kubernetes.io/os" : "linux" },
          )
        }
      }
      affinity = {
        nodeAffinity = local.node_affinity
      }
      tolerations = local.tolerations
    }
  }
}

resource "helm_release" "ingress_nginx" {
  count = var.ingress_nginx != null ? 1 : 0

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  name       = "ingress-nginx"
  version    = var.ingress_nginx.version
  namespace  = var.ingress_nginx.namespace
  values     = [yamlencode(merge(local.ingress_nginx_helm_values, var.ingress_nginx.helm_values))]
}
