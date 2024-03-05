module "external_dns" {
  count  = var.external_dns != null ? 1 : 0
  source = "./modules/google-external-dns"

  helm_chart_version       = var.external_dns.version
  project_id               = var.external_dns.gcp_project_id
  cluster_name             = var.external_dns.cluster_name
  k8s_namespace            = var.external_dns.namespace
  gcp_service_account_name = var.external_dns.gcp_service_account_name
  k8s_service_account_name = var.external_dns.k8s_service_account_name
  helm_values              = var.external_dns.helm_values
  domain                   = var.external_dns.domain
  sources                  = var.external_dns.sources
  tolerations              = local.tolerations
  node_affinity            = local.node_affinity
}
