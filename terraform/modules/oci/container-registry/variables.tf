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

