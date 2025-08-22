# TPU Multihost Training Infrastructure

Terraform configuration for setting up Google Cloud TPU v6e pods for multihost training with attached storage.

## Architecture

- **TPU Pod**: v6e-256 with multihost topology
- **Data Storage**: Hyperdisk ML created from snapshot (read-only, multi-read)
- **Checkpoint Storage**: Cloud Storage bucket with gcsfuse mounting
- **Network**: Custom VPC with 8,896 MTU for optimal performance
- **IAM**: Dedicated service account with storage access
- **Startup**: Automated disk/bucket mounting and environment setup

## Usage

**Step 1: Create Bucket and Service Account** (do this first):
```bash
cd bucket
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your project details
terraform init
terraform apply
cd ..
```

**Step 2: Create TPU Infrastructure**:
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with bucket name and service account ID from Step 1
terraform init
terraform plan
terraform apply
```

**Step 3: Connect to TPU VM**:
```bash
gcloud compute tpus tpu-vm ssh tpu-training-vm --zone=us-central2-b
```

## Configuration

### Required Variables
- `project_id`: Your GCP project ID
- `data_snapshot_name`: Name of your data snapshot
- `checkpoint_bucket_name`: Name of bucket created in Step 1
- `service_account_id`: Service account ID created in Step 1

### Optional Variables
- `tpu_accelerator_type`: TPU type (default: v6e-256)
- `tpu_topology`: Pod topology (default: 8x16)
- `data_disk_size_gb`: Data disk size (default: 1000 GB)

## Storage Setup

The startup script automatically:
- Mounts data disk at `/mnt/data` (read-only)
- Mounts checkpoint bucket at `/mnt/checkpoints` using gcsfuse
- Sets up environment variables including bucket name
- Installs JAX, TensorFlow, and gcsfuse

**Cloud Storage Benefits**:
- Persistent across TPU VM restarts
- Protected from accidental deletion (`prevent_destroy = true`)
- Versioning enabled for checkpoint safety
- Accessible from multiple TPU VMs simultaneously

## Training Setup

After infrastructure is ready:
1. SSH into the TPU VM
2. Upload your training code to `/opt/training`
3. Run training with environment variables:
   - `DATA_DIR=/mnt/data`
   - `CHECKPOINT_DIR=/mnt/checkpoints`
   - `CHECKPOINT_BUCKET` (Cloud Storage bucket name)
   - `TPU_NAME` and `TPU_ZONE` (auto-set)

## Architecture Design

This setup uses a **separated architecture** where bucket and TPU infrastructure are managed independently:

### Benefits
- **Bucket persistence**: Checkpoints survive TPU infrastructure changes
- **Independent scaling**: Create/destroy TPU VMs without affecting storage
- **Reusability**: Same bucket can be shared across multiple training runs
- **Cost optimization**: Only pay for TPU compute when needed

### Files
- `bucket/bucket-only.tf` - Creates bucket and service account (run first)
- `main.tf` - Creates TPU infrastructure, references existing bucket
- `bucket/terraform.tfvars.example` - Configuration template for bucket creation

## Cleanup

**Destroy TPU infrastructure** (preserves bucket):
```bash
terraform destroy
```

**Destroy everything including bucket** (⚠️ deletes all checkpoints):
```bash
terraform destroy
cd bucket
terraform destroy
```