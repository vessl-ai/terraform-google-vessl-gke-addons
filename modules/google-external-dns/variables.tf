variable "project_id" {
  type        = string
  description = "The GCP project ID"
}

variable "cluster_name" {
  type        = string
  description = "The name of the GKE cluster"
}

variable "helm_repo_url" {
  type        = string
  default     = "https://kubernetes-sigs.github.io/external-dns/"
  description = "The Helm repository URL for external-dns"
}

variable "helm_chart_name" {
  type        = string
  default     = "external-dns"
  description = "The Helm chart name for external-dns"
}

variable "helm_chart_version" {
  type        = string
  default     = "1.14.3"
  description = "The Helm chart version for external-dns"
}

variable "helm_release_name" {
  type        = string
  default     = "external-dns"
  description = "The Helm release name for external-dns"
}

variable "helm_values" {
  type        = map(any)
  default     = {}
  description = "Additional Helm values for external-dns"
}

variable "k8s_create_namespace" {
  type        = bool
  default     = false
  description = "Whether to create k8s namespace with name defined by `k8s_namespace`"
}

variable "k8s_namespace" {
  type        = string
  default     = "kube-system"
  description = "The k8s namespace in which the external-dns service account has been created"
}

variable "k8s_service_account_name" {
  type        = string
  default     = "external-dns"
  description = "The k8s external-dns service account name"
}

variable "gcp_service_account_name" {
  type        = string
  default     = "external-dns"
  description = "GCP service account name to access Cloud DNS"
}

variable "domain" {
  type        = string
  description = "Domain to be used by external-dns"
}

variable "sources" {
  type        = list(string)
  description = "List of sources to be used by external-dns (service, ingress)"
}

variable "node_affinity" {
  type    = map(any)
  default = {}
}

variable "tolerations" {
  type    = list(any)
  default = []
}
