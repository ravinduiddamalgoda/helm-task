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
  env_name       = "${include.common.locals.name_prefix}-${include.common.locals.prefix_env}-${include.common.locals.env}"
  
  # Repository configuration
  repository_name = "koci-images"
  is_public       = false
  
  # IAM configuration
  create_iam_policy         = true
  worker_dynamic_group_name = "oke-workers-${include.common.locals.env}"
  function_dynamic_group_name = "functions-${include.common.locals.env}"

  # Tags
  freeform_tags = include.common.locals.common_tags
  defined_tags  = {}
} 