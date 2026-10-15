terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

# Proveedor AWS apuntando a Moto (sin credenciales reales, sin costo)
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    lambda = "http://localhost:5000"
    iam    = "http://localhost:5000"
    eks    = "http://localhost:5000"
    ecr    = "http://localhost:5000"
    sts    = "http://localhost:5000"
  }
}

# Cluster local real (el "nodo de cómputo" de la demo)
resource "kind_cluster" "demo_eks" {
  name           = var.cluster_name
  node_image     = "kindest/node:v1.28.0"
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"

      extra_port_mappings {
        container_port = 30080
        host_port      = 30080
        protocol       = "TCP"
      }

      extra_port_mappings {
        container_port = 30081
        host_port      = 30081
        protocol       = "TCP"
      }

      extra_port_mappings {
        container_port = 30090
        host_port      = 30090
        protocol       = "TCP"
      }
    }

    node {
      role = "worker"
    }
  }
}

provider "kubernetes" {
  host                   = kind_cluster.demo_eks.endpoint
  client_certificate     = kind_cluster.demo_eks.client_certificate
  client_key             = kind_cluster.demo_eks.client_key
  cluster_ca_certificate = kind_cluster.demo_eks.cluster_ca_certificate
}

provider "helm" {
  kubernetes {
    host                   = kind_cluster.demo_eks.endpoint
    client_certificate     = kind_cluster.demo_eks.client_certificate
    client_key             = kind_cluster.demo_eks.client_key
    cluster_ca_certificate = kind_cluster.demo_eks.cluster_ca_certificate
  }
}
