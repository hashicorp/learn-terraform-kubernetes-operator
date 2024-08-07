# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.27.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.12.1"
    }
  }
}

variable "host" {
  type = string
}

variable "client_certificate" {
  type = string
}

variable "client_key" {
  type = string
}

variable "cluster_ca_certificate" {
  type = string
}

variable "aws_access_key_id" {
  type = string
}

variable "aws_secret_access_key" {
  type = string
}

variable "tfc_token" {
  type = string
}

variable "tfe_address" {
  type = string
}

provider "kubernetes" {
  host = var.host

  client_certificate     = base64decode(var.client_certificate)
  client_key             = base64decode(var.client_key)
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
}

// Create namespace for Operator
resource "kubernetes_namespace" "tfc-operator-system" {
  metadata {
    name = "tfc-operator-system"
  }
}

// Create namespace for application
resource "kubernetes_namespace" "edu" {
  metadata {
    name = "edu"
  }
}

// Create terraformrc secret for Operator
resource "kubernetes_secret" "terraformrc" {
  metadata {
    name      = "terraformrc"
    namespace = kubernetes_namespace.edu.metadata[0].name
  }

  data = {
    "token" = var.tfc_token
  }
}

// Create workspace secret for Operator
resource "kubernetes_secret" "workspacesecrets" {
  metadata {
    name      = "workspacesecrets"
    namespace = kubernetes_namespace.edu.metadata[0].name
  }

  data = {
    "AWS_ACCESS_KEY_ID"     = var.aws_access_key_id
    "AWS_SECRET_ACCESS_KEY" = var.aws_secret_access_key
  }
}

provider "helm" {
  kubernetes {
    host = var.host

    client_certificate     = base64decode(var.client_certificate)
    client_key             = base64decode(var.client_key)
    cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
  }
}

// Terraform Cloud Operator for Kubernetes helm chart
resource "helm_release" "operator" {
  name       = "terraform-operator"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "hcp-terraform-operator"
  version    = "2.6.0"

  namespace        = kubernetes_namespace.tfc-operator-system.metadata[0].name
  create_namespace = true

  set {
    name  = "operator.watchedNamespaces"
    value = "{${kubernetes_namespace.edu.metadata[0].name}}"
  }

  /* Uncomment to deploy to Terraform Enterprise
  set {
    name  = "operator.tfeAddress"
    value = var.tfe_address
  }
  */
}
