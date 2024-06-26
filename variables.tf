variable "external_dns" {
  type = object({
    gcp_project_id           = string
    cluster_name             = string
    namespace                = optional(string, "kube-system")
    version                  = optional(string, "1.14.3")
    helm_values              = optional(map(any), {})
    k8s_service_account_name = optional(string, "external-dns")
    gcp_service_account_name = optional(string, "external-dns")
    sources                  = optional(list(string), ["service"])
    domain                   = string
  })
  default = null
}

variable "ingress_nginx" {
  type = object({
    namespace           = optional(string, "kube-system")
    version             = optional(string, "4.10.0")
    service_annotations = optional(map(string), {})
    helm_values         = optional(map(any), {})
  })
  default = null
}

variable "cert_manager" {
  type = object({
    namespace        = optional(string, "kube-system")
    version          = optional(string, "v1.14.3")
    domain           = string
    cert_email       = string
    cert_secret_name = string
    helm_values      = optional(map(any), {})
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
