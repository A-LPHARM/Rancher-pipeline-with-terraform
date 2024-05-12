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

data "kubectl_file_documents" "alb_crds" {
  content = data.http.manifestfile.response_body
}

resource "kubectl_manifest" "alb_crds" {
  for_each  = data. kubectl_file_documents.alb_crds.manifests
  yaml_body = each.value
}