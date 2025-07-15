# OCI Container Registry Repository
resource "oci_artifacts_container_repository" "main" {
  compartment_id = var.compartment_id
  display_name   = var.repository_name
  is_public      = var.is_public


  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

