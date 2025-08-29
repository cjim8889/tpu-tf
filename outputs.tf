output "tpu_vm_name" {
  description = "Name of the TPU VM (customizable via variables)"
  value       = google_tpu_v2_vm.tpu_vm.name
}

output "tpu_vm_id" {
  description = "ID of the created TPU VM"
  value       = google_tpu_v2_vm.tpu_vm.id
}

output "network_name" {
  description = "Name of the TPU network (customizable via variables)"
  value       = google_compute_network.tpu_network.name
}

output "subnet_name" {
  description = "Name of the TPU subnet (customizable via variables)"
  value       = google_compute_subnetwork.tpu_subnet.name
}

output "data_disk_name" {
  description = "Name of the TPU data disk (customizable via variables)"
  value       = google_compute_disk.data_disk.name
}

output "checkpoint_bucket_name" {
  description = "Name of the referenced checkpoint storage bucket"
  value       = data.google_storage_bucket.checkpoint_bucket.name
}

output "checkpoint_bucket_url" {
  description = "URL of the referenced checkpoint storage bucket"
  value       = data.google_storage_bucket.checkpoint_bucket.url
}

output "referenced_service_account_email" {
  description = "Email of the referenced TPU service account"
  value       = data.google_service_account.tpu_service_account.email
}

output "ssh_command" {
  description = "SSH command to connect to TPU VM"
  value       = "gcloud compute tpus tpu-vm ssh ${google_tpu_v2_vm.tpu_vm.name} --zone=${var.zone}"
}