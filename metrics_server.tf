locals {
  metrics_server_node_affinity = {
    preferredDuringSchedulingIgnoredDuringExecution = [
      for nodeSelector in var.node_selectors : {
        weight = 1
        preference = {
          matchExpressions = [{
            key      = nodeSelector.key
            operator = "In"
            values   = [nodeSelector.value]
          }]
        }
      }
    ]
  }

  // https://github.com/kubernetes-sigs/metrics-server/blob/796fc0f832c1ac444c44f88a952be87524456e07/charts/metrics-server/values.yaml
  metrics_server_helm_values = {
    tolerations = var.tolerations
    affinity = {
      nodeAffinity = local.metrics_server_node_affinity
    }
  }
}

resource "helm_release" "metrics_server" {
  count = var.metrics_server != null ? 1 : 0

  repository = "https://kubernetes-sigs.github.io/metrics-server"
  chart      = "metrics-server"
  name       = "metrics-server"
  version    = var.metrics_server.version
  namespace  = var.metrics_server.namespace
  values     = [yamlencode(local.metrics_server_helm_values)]

  dynamic "set" {
    for_each = var.metrics_server.helm_values
    content {
      name  = set.key
      value = set.value
    }
  }
}
