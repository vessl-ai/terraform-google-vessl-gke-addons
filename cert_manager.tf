module "cert_manager" {
  count  = var.external_dns != null && var.cert_manager != null ? 1 : 0
  source = "./modules/cert-manager"

  helm_chart_version         = var.cert_manager.version
  project_id                 = var.external_dns.gcp_project_id
  k8s_namespace              = var.cert_manager.namespace
  k8s_service_account_name   = var.external_dns.k8s_service_account_name
  k8s_create_service_account = false
  helm_values                = var.cert_manager.helm_values
  domain                     = var.cert_manager.domain
  cert_email                 = var.cert_manager.cert_email
  cert_secret_name           = var.cert_manager.cert_secret_name
  tolerations                = local.tolerations
  node_affinity              = local.node_affinity
}
