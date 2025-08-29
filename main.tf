terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "6.49.1"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Local values for resource naming
locals {
  name_suffix = var.resource_name_suffix != "" ? "-${var.resource_name_suffix}" : ""
  
  network_name    = var.network_name != "" ? var.network_name : "${var.resource_name_prefix}-network${local.name_suffix}"
  subnet_name     = var.subnet_name != "" ? var.subnet_name : "${var.resource_name_prefix}-subnet${local.name_suffix}"
  firewall_name   = var.firewall_name != "" ? var.firewall_name : "${var.resource_name_prefix}-internal${local.name_suffix}"
  data_disk_name  = var.data_disk_name != "" ? var.data_disk_name : "${var.resource_name_prefix}-data-disk-auto${local.name_suffix}"
  tpu_vm_name     = var.tpu_vm_name != "" ? var.tpu_vm_name : "${var.resource_name_prefix}-training-vm${local.name_suffix}"
}

# Create custom network for TPU with high MTU
resource "google_compute_network" "tpu_network" {
  name                    = local.network_name
  auto_create_subnetworks = false
  mtu                     = 8896
}

resource "google_compute_subnetwork" "tpu_subnet" {
  name          = local.subnet_name
  ip_cidr_range = "10.0.0.0/16"
  region        = var.region
  network       = google_compute_network.tpu_network.id
}

# Firewall rules for TPU communication
resource "google_compute_firewall" "tpu_internal" {
  name    = local.firewall_name
  network = google_compute_network.tpu_network.name

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]
}

# Create ML-Balanced disk from snapshot for data
resource "google_compute_disk" "data_disk" {
  provider = google-beta
  name                   = local.data_disk_name
  type                   = "hyperdisk-ml"
  access_mode            = "READ_ONLY_MANY"
  zone                   = var.zone
  size                   = var.data_disk_size_gb
  snapshot               = var.data_snapshot_name
  # provisioned_throughput = 1000
  # provisioned_iops = 6600

  lifecycle {
    prevent_destroy = false
  }
}

# Reference existing checkpoint bucket
data "google_storage_bucket" "checkpoint_bucket" {
  name = var.checkpoint_bucket_name
}

# Reference existing service account for bucket access
data "google_service_account" "tpu_service_account" {
  account_id = var.service_account_id
}

# TPU v2 VM with multihost configuration
resource "google_tpu_v2_vm" "tpu_vm" {
  provider = google-beta
  name             = local.tpu_vm_name
  zone             = var.zone
  runtime_version  = var.runtime_version
  accelerator_type = var.tpu_accelerator_type

  network_config {
    enable_external_ips = true
    network             = google_compute_network.tpu_network.id
    subnetwork          = google_compute_subnetwork.tpu_subnet.id
  }

  scheduling_config {
    spot = var.spot
  }

  # Attach data disk in read-only mode for multi-read access
  data_disks {
    source_disk = google_compute_disk.data_disk.id
    mode        = "READ_ONLY"
  }


  # accelerator_config {
  #   type     = var.tpu_accelerator_type
  #   topology = var.tpu_topology
  # }

  service_account {
    email = data.google_service_account.tpu_service_account.email
    scope = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/devstorage.read_write"
    ]
  }

  metadata = {
    startup-script    = file(var.startup_script_path)
    checkpoint-bucket = data.google_storage_bucket.checkpoint_bucket.name
  }

  labels = {
    environment = "training"
    purpose     = "multihost-tpu"
  }
}
