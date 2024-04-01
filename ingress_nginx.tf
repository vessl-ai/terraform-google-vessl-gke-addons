locals {
  // https://github.com/kubernetes/ingress-nginx/blob/main/charts/ingress-nginx/values.yaml
  ingress_nginx_helm_values = {
    controller = {
      service = {
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
      extraArgs = var.cert_manager != null ? {
        default-ssl-certificate = "${var.cert_manager.namespace}/${var.cert_manager.cert_secret_name}"
      } : {}
      resources = {
        requests = {
          cpu    = "300m"
          memory = "500Mi"
        }
      }
      config = {
        proxy-body-size = "1g"
      }
      minAvailable = 2
      autoscaling = {
        enabled                           = true
        minReplicas                       = 2
        maxReplicas                       = 11
        targetCPUUtilizationPercentage    = 50
        targetMemoryUtilizationPercentage = 80
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
