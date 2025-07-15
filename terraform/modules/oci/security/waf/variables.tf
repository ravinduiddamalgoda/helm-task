variable "compartment_id" {
  description = "The OCID of the compartment where the WAF policy will be created"
  type        = string
}

variable "env_name" {
  description = "Environment name for the WAF policy"
  type        = string
}

variable "waf_rules" {
  description = "List of WAF protection rules"
  type = list(object({
    name        = string
    action_name = string
    condition   = string
    capability_key = string
    version     = optional(string, "1.0")
  }))
  default = []
}

# variable "max_request_size_in_bytes" {
#   description = "Maximum request size in bytes"
#   type        = number
#   default     = 10485760  # 10MB
# }

variable "freeform_tags" {
  description = "Freeform tags for the WAF policy"
  type        = map(string)
  default     = {}
} 