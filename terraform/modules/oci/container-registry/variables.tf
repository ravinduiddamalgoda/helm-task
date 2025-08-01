variable "compartment_id" {
  description = "OCID of the compartment for the container registry"
  type        = string
}

variable "env_name" {
  description = "Environment name for resource naming"
  type        = string
}

variable "repository_name" {
  description = "Name of the container repository"
  type        = string
  default     = "koci-images"
}


variable "is_public" {
  description = "Whether the repository is public"
  type        = bool
  default     = false
}


variable "freeform_tags" {
  description = "Freeform tags for resources"
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags for resources"
  type        = map(string)
  default     = {}
} 

variable "create_iam_policy" {
  description = "Whether to create IAM policy for registry access"
  type        = bool
  default     = true
}

variable "worker_dynamic_group_name" {
  description = "Name of the OKE worker dynamic group"
  type        = string
  default     = ""
}

variable "function_dynamic_group_name" {
  description = "Name of the function dynamic group"
  type        = string
  default     = ""
}