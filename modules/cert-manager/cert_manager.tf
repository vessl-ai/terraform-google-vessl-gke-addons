terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

locals {
  // https://github.com/cert-manager/cert-manager/blob/master/deploy/charts/cert-manager/values.yaml
  cert_manager_helm_values = {
    serviceAccount = {
      create = var.k8s_create_service_account
      name   = var.k8s_service_account_name
    }
    affinity = {
      nodeAffinity = var.node_affinity
    }
    tolerations = var.tolerations
  }
}

data "kubectl_path_documents" "cert_manager_crds" {
  pattern = "${path.module}/files/${var.helm_chart_version}.crds.yaml"
}

resource "kubectl_manifest" "cert_manager_crds" {
  count     = length(data.kubectl_path_documents.cert_manager_crds.documents)
  yaml_body = element(data.kubectl_path_documents.cert_manager_crds.documents, count.index)
}

resource "helm_release" "cert_manager" {
  depends_on = [kubectl_manifest.cert_manager_crds]

  repository = var.helm_repo_url
  chart      = var.helm_chart_name
  name       = var.helm_release_name
  namespace  = var.k8s_namespace
  version    = var.helm_chart_version
  values     = [yamlencode(merge(local.cert_manager_helm_values, var.helm_values))]
}

resource "kubectl_manifest" "cert_manager_issuer" {
  depends_on = [kubectl_manifest.cert_manager_crds]

  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: "dev@vessl.ai"
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
      - dns01:
          cloudDNS:
            project: ${var.project_id}
YAML
}

resource "kubectl_manifest" "certificate" {
  depends_on = [kubectl_manifest.cert_manager_issuer]

  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: oregon-dev-google-cluster-vssl-ai
  namespace: ${var.k8s_namespace}
spec:
  secretName: wildcard-cert
  issuerRef:
    kind: ClusterIssuer
    name: letsencrypt-prod
  dnsNames:
    - "*.${var.domain}"
  acme:
    config:
      - dns01:
          provider: dns
        domains:
          - "*.${var.domain}"
YAML
}
