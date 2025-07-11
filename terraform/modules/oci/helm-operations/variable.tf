# Copyright (c) 2024 Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

variable "compartment_id" {
  description = "OCI Compartment ID"
  type        = string
}

variable "operator_private_ip" {
  description = "Private IP address of the operator instance"
  type        = string
}

variable "operator_user" {
  description = "SSH user for the operator instance"
  type        = string
  default     = "opc"
}

variable "operator_ssh_key" {
  description = "SSH private key for connecting to the operator instance"
  type        = string
  sensitive   = true
}

variable "operator_id" {
  description = "OCI instance ID of the operator"
  type        = string
  default     = null
}

# variable "bastion_host" {
#   description = "Bastion host public IP for SSH tunneling"
#   type        = string
#   default     = null
# }

variable "bastion_user" {
  description = "SSH user for the bastion host"
  type        = string
  default     = "opc"
}

variable "bastion_ssh_key" {
  description = "SSH private key for connecting to the bastion host"
  type        = string
  default     = null
  sensitive   = true
}

variable "helm_operations" {
  description = "List of helm operations to execute"
  type = list(object({
    name        = string
    description = string
    commands    = list(string)
    triggers    = map(string)
  }))
  default = []
}

variable "state_id" {
  description = "Unique identifier for this helm operations state"
  type        = string
}

variable "region" {
  description = "OCI region"
  type        = string
}

variable "tag_namespace" {
  description = "Tag namespace for resources"
  type        = string
  default     = "koci"
}

variable "defined_tags" {
  description = "Defined tags for resources"
  type        = map(string)
  default     = {}
}

variable "freeform_tags" {
  description = "Freeform tags for resources"
  type        = map(string)
  default     = {}
}

variable "use_defined_tags" {
  description = "Whether to use defined tags"
  type        = bool
  default     = false
} 

variable "bastion_host_public_ip" { 
  description = "Bastion host public IP for SSH tunneling"
  type        = string
  default     = null
}

# variable "helm_charts" {
#   description = "List of helm charts to transfer and install"
#   type = list(object({
#     name        = string
#     description = string
#     local_path  = string
#     namespace   = string
#     values_file = optional(string)
#     install_cmd = optional(string)
#     triggers    = map(string)
#   }))
#   default = []
# }