include "common" {
  path = find_in_parent_folders("env-common.hcl")
  expose = true
}


terraform {
  source = "../../../../terraform//modules/oci/container-registry"
}

inputs = {
  # Core configuration
  compartment_id = include.common.locals.compartment_ocid
  env_name       = "${include.common.locals.name_prefix}-${include.common.locals.env}"
  
  # Repository configuration
  repository_name = "koci-images"
  is_public       = false
#   

  # Tags
  freeform_tags = include.common.locals.common_tags
  defined_tags  = {}
} 