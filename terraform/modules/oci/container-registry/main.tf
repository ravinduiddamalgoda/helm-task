# OCI Container Registry Repository
resource "oci_artifacts_container_repository" "main" {
  compartment_id = var.compartment_id
  display_name   = var.repository_name
  is_public      = var.is_public
    

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_identity_policy" "repo_access_policy" {
  compartment_id = var.compartment_id
  name           = "${var.repository_name}-policy"
  description    = "Allow access to the OCI Container Registry repository"

  statements = [
    "Allow dynamic-group ${var.worker_dynamic_group_name} to read repos in compartment id ${var.compartment_id}",
    "Allow dynamic-group ${var.function_dynamic_group_name} to read repos in compartment id ${var.compartment_id}",
    "Allow group Administrators to manage repos in compartment id ${var.compartment_id}"
  ]
}
