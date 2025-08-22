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

# Create custom network for TPU with high MTU
resource "google_compute_network" "tpu_network" {
  name                    = "tpu-network"
  auto_create_subnetworks = false
  mtu                     = 8896
}

resource "google_compute_subnetwork" "tpu_subnet" {
  name          = "tpu-subnet"
  ip_cidr_range = "10.0.0.0/16"
  region        = var.region
  network       = google_compute_network.tpu_network.id
}

# Firewall rules for TPU communication
resource "google_compute_firewall" "tpu_internal" {
  name    = "tpu-internal"
  network = google_compute_network.tpu_network.name

  allow {
    protocol = "tcp"
    ports    = ["22", "8470-8485"]
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.0.0.0/16"]
}

# Create ML-Balanced disk from snapshot for data
resource "google_compute_disk" "data_disk" {
  provider = google-beta
  name                   = "tpu-data-disk"
  type                   = "hyperdisk-ml"
  access_mode            = "READ_ONLY_SINGLE"
  zone                   = var.zone
  size                   = var.data_disk_size_gb
  snapshot               = var.data_snapshot_name
  provisioned_throughput = 1000

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
  name             = "tpu-training-vm"
  zone             = var.zone
  runtime_version  = var.runtime_version
  accelerator_type = var.tpu_accelerator_type

  network_config {
    enable_external_ips = true
    network             = google_compute_network.tpu_network.id
    subnetwork          = google_compute_subnetwork.tpu_subnet.id
  }

  scheduling_config {
    preemptible = var.spot
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
