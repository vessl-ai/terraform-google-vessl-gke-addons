locals {
  external_dns_helm_values = {
    provider = "google",
    google = {
      project = var.project_id
    }
    serviceAccount = {
      create = true
      name   = var.k8s_service_account_name
      annotations = {
        "iam.gke.io/gcp-service-account" = "external-dns@${var.project_id}.iam.gserviceaccount.com"
      }
    }
    sources      = var.sources
    domainFilter = var.domain_filters
    affinity = {
      nodeAffinity = var.node_affinity
    }
    tolerations = var.tolerations
  }
}

resource "helm_release" "external_dns" {
  depends_on = [module.external_dns_workload_identity]

  name             = var.helm_release_name
  repository       = var.helm_repo_url
  chart            = var.helm_chart_name
  version          = var.helm_chart_version
  create_namespace = var.k8s_create_namespace
  namespace        = var.k8s_namespace
  values           = [yamlencode(merge(local.external_dns_helm_values, var.helm_values))]
}
