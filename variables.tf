variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central2"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central2-b"
}

variable "data_snapshot_name" {
  description = "Name of the snapshot containing training data"
  type        = string
}

variable "checkpoint_bucket_name" {
  description = "Name of the existing checkpoint bucket (created separately)"
  type        = string
}

variable "service_account_id" {
  description = "Account ID of the existing service account for bucket access"
  type        = string
}

variable "tpu_accelerator_type" {
  description = "TPU accelerator type"
  type        = string
  default     = "v6e-256"
}

variable "tpu_topology" {
  description = "TPU topology for multihost setup"
  type        = string
  default     = "8x16"
}

variable "runtime_version" {
  description = "TPU runtime version"
  type        = string
  default     = "tpu-vm-tf-2.15.0-pjrt"
}

variable "data_disk_size_gb" {
  description = "Size of the ML-Balanced disk in GB"
  type        = number
  default     = 1000
}

variable "startup_script_path" {
  description = "Path to startup script"
  type        = string
  default     = "./startup.sh"
}

variable "spot" {
  description = "Use spot TPU instances"
  type        = bool
  default     = false
}

# Naming variables
variable "resource_name_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "tpu"
}

variable "resource_name_suffix" {
  description = "Suffix for all resource names (optional)"
  type        = string
  default     = ""
}

# Individual resource name overrides (optional)
variable "network_name" {
  description = "Custom name for the TPU network (overrides prefix/suffix if provided)"
  type        = string
  default     = ""
}

variable "subnet_name" {
  description = "Custom name for the TPU subnet (overrides prefix/suffix if provided)"
  type        = string
  default     = ""
}

variable "firewall_name" {
  description = "Custom name for the TPU firewall rule (overrides prefix/suffix if provided)"
  type        = string
  default     = ""
}

variable "data_disk_name" {
  description = "Custom name for the TPU data disk (overrides prefix/suffix if provided)"
  type        = string
  default     = ""
}

variable "tpu_vm_name" {
  description = "Custom name for the TPU VM (overrides prefix/suffix if provided)"
  type        = string
  default     = ""
}