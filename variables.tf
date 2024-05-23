locals {
  cluster_name = "ase-eks-${random_string.suffix.result}"
}
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr1" {
  default = "10.0.0.0/24"
}

variable "public_subnet_cidr2" {
  default = "10.0.1.0/24"
}

variable "enable_cluster_logs" {
  description = "Flag to enable cluster logs"
  type        = bool
  default     = false
}

locals {
  cluster_log_types = var.enable_cluster_logs ? ["audit", "api", "authenticator", "scheduler", "controllerManager"] : []
}

variable "enable_encryption" {
  description = "Enable encryption for Kubernetes secrets"
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "KMS Key ARN for encrypting Kubernetes secrets"
  type        = string
  default = "value will be provided when it is used"
}
