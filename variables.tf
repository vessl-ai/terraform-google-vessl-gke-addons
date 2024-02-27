variable "ingress_nginx" {
  type = object({
    namespace           = optional(string, "kube-system")
    version             = optional(string, "4.9.1")
    service_annotations = optional(map(string), {})
    ssl_termination     = optional(bool, true)
    extra_chart_values  = optional(map(string), {})
  })
  default = null
}

variable "node_affinity" {
  type = list(object({
    key      = string
    operator = string
    values   = optional(list(string))
  }))
  default = [{
    key      = "v1.k8s.vessl.ai/dedicated"
    operator = "In"
    values   = ["manager"]
  }]
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
