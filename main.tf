###### Providers ######
terraform {
  required_version = ">=1.8"
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }
  }
}

provider "kubectl" {
    config_path    = "~/.kube/config"
}

###### Resources ######
data "http" "manifestfile" {
  url = "https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
}

data "kubectl_file_documents" "argocd" {
  content = data.http.manifestfile.response_body
}

# Namespace resource for argocd
resource "kubectl_manifest" "argocd_namespace" {
  yaml_body = <<YAML
apiVersion: v1
kind: Namespace
metadata:
  name: argocd
YAML
}

# Apply ArgoCD manifests
resource "kubectl_manifest" "argocd" {
  for_each  = data.kubectl_file_documents.argocd.manifests
  yaml_body = each.value
  override_namespace = "argocd"
  depends_on = [kubectl_manifest.argocd_namespace]
}
