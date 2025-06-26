variable "create_state_bucket" {
  description = "Whether to create the OCI bucket used for Terraform state. Set to false when the bucket already exists or is managed elsewhere."
  type    = bool
  default = false
} 

variable "compartment_id" { ##hardcode ADDED
  description = ""
  type        = string
  
}

variable "namespace" {  ##hardcode ADDED
  description = ""
  type        = string
  
}

variable "bucket_name" {  ##hardcode ADDED
  description = "" 
  type        = string
  
}
variable "common_tags" {  ##hardcode ADDED
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}