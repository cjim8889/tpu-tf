# Standalone bucket configuration
# Run this first to create bucket and service account

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.bucket_project_id
  region  = var.bucket_region
}

variable "bucket_project_id" {
  description = "GCP Project ID for bucket"
  type        = string
}

variable "bucket_region" {
  description = "GCP Region for bucket"
  type        = string
  default     = "us-central2"
}

variable "bucket_name_suffix" {
  description = "Suffix for bucket name"
  type        = string
  default     = "tpu-checkpoints"
}

# Create TPU service account for bucket access
resource "google_service_account" "tpu_bucket_service_account" {
  account_id   = "tpu-bucket-sa"
  display_name = "TPU Bucket Service Account"
  description  = "Service account for TPU training with Cloud Storage bucket access"
}

# Create Cloud Storage bucket for checkpoints
resource "google_storage_bucket" "checkpoint_bucket" {
  name          = "${var.bucket_project_id}-${var.bucket_name_suffix}"
  location      = var.bucket_region
  force_destroy = false

  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = true
  }

  # Enable versioning for checkpoint safety
  versioning {
    enabled = true
  }

  # Uniform bucket-level access
  uniform_bucket_level_access = true

  # Lifecycle management for cost optimization
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }
}

# IAM binding for service account to access bucket
resource "google_storage_bucket_iam_member" "bucket_access" {
  bucket = google_storage_bucket.checkpoint_bucket.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.tpu_bucket_service_account.email}"
}

output "bucket_name" {
  description = "Name of the created checkpoint bucket"
  value       = google_storage_bucket.checkpoint_bucket.name
}

output "bucket_url" {
  description = "URL of the created checkpoint bucket"
  value       = google_storage_bucket.checkpoint_bucket.url
}

output "service_account_email" {
  description = "Email of the created service account"
  value       = google_service_account.tpu_bucket_service_account.email
}

output "service_account_id" {
  description = "Account ID of the created service account"
  value       = google_service_account.tpu_bucket_service_account.account_id
}