variable "project_id" {
  type        = string
  description = "The GCP project ID"
}

variable "helm_repo_url" {
  type        = string
  default     = "https://charts.jetstack.io"
  description = "The Helm repository URL for cert-manager"
}

variable "helm_chart_name" {
  type        = string
  default     = "cert-manager"
  description = "The Helm chart name for cert-manager"
}

variable "helm_chart_version" {
  type        = string
  default     = "v1.14.3"
  description = "The Helm chart version for cert-manager"
}

variable "helm_release_name" {
  type        = string
  default     = "cert-manager"
  description = "The Helm release name for cert-manager"
}

variable "helm_values" {
  type        = map(any)
  default     = {}
  description = "Additional Helm values for cert-manager"
}

variable "k8s_create_namespace" {
  type        = bool
  default     = false
  description = "Whether to create k8s namespace with name defined by `k8s_namespace`"
}

variable "k8s_namespace" {
  type        = string
  default     = "kube-system"
  description = "The k8s namespace in which the cert-manager service account has been created"
}

variable "k8s_create_service_account" {
  type        = bool
  default     = false
  description = "Whether to create k8s service account with name defined by `k8s_service_account_name`"
}

variable "k8s_service_account_name" {
  type        = string
  default     = "cert-manager"
  description = "The k8s cert-manager service account name"
}

variable "domain" {
  type        = string
  description = "Domain to be used by cert-manager"
}

variable "cert_secret_name" {
  type    = string
  default = "wildcard-cert"
}

variable "cert_email" {
  type = string
}

variable "node_affinity" {
  type    = map(any)
  default = {}
}

variable "tolerations" {
  type    = list(any)
  default = []
}
