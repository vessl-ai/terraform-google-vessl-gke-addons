module "external_dns_workload_identity" {
  source              = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version             = "~> 30.0.0"
  project_id          = var.project_id
  cluster_name        = var.cluster_name
  namespace           = var.k8s_namespace
  name                = var.gcp_service_account_name
  k8s_sa_name         = var.k8s_service_account_name
  roles               = ["roles/dns.admin"]
  use_existing_k8s_sa = true
  annotate_k8s_sa     = false
}
