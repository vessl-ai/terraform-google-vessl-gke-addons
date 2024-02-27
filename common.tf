locals {
  node_affinity = {
    requiredDuringSchedulingIgnoredDuringExecution = {
      nodeSelectorTerms = [
        for expression in var.node_affinity : {
          matchExpressions = [
            { for key, value in expression : key => value if key != null }
          ]
        }
      ]
    }
  }
  tolerations = [
    for t in var.tolerations : { for key, value in t : key => value if value != null }
  ]
}