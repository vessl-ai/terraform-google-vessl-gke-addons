variable "metrics_server" {
  type = object({
    namespace = optional(string, "kube-system")
    version   = optional(string, "3.11.0")
    // https://github.com/kubernetes-sigs/metrics-server/blob/d7f6d5b64fcd535c63efbfc573da86767997286d/charts/metrics-server/values.yaml
    helm_values = optional(map(any), {})
  })
  default = null
}

variable "node_selectors" {
  type = list(object({
    key   = string
    value = string
  }))
  default = [{
    key   = "v1.k8s.vessl.ai/dedicated"
    value = "manager"
  }]
}

variable "tolerations" {
  type = list(object({
    key      = string
    operator = string
    value    = optional(string)
    effect   = optional(string)
  }))
  default = [{
    key      = "v1.k8s.vessl.ai/dedicated"
    operator = "Exists"
    effect   = "NoSchedule"
  }]
}

variable "tags" {
  type = map(string)
  default = {
    "vessl:managed" : "true",
  }
}
