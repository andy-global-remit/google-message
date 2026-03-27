terraform {
  required_version = ">= 1.9.8"

  # Remote state: pass bucket and prefix at init time, for example:
  #   terraform init -backend-config=backend.hcl
  # See backend.hcl.example in this directory.
  backend "gcs" {}

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0.0, < 7.0.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 6.0.0, < 7.0.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}
