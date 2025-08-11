# dynamically from Doppler secret HOME_REGION
provider "oci" {
  alias  = "home"
  region = var.home_region 
}

# OCI Container Registry Repository
resource "oci_artifacts_container_repository" "main" {
  compartment_id = var.compartment_id
  display_name   = var.repository_name
  is_public      = var.is_public
    

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# new Create Dynamic Group for OKE workloads
resource "oci_identity_dynamic_group" "oke_workload_dg" {
  provider       = oci.home
  compartment_id = var.root_compartment_id
  name           = "oke-workload-dg"
  description    = "Dynamic group for OKE workloads in a specific compartment"

  matching_rule = "ALL {instance.compartment.id = '${var.compartment_id}'}"
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

# new Create IAM Policy for the new OKE workload DG
resource "oci_identity_policy" "workload_repo_access" {
  provider       = oci.home
  compartment_id = var.root_compartment_id
  name           = "oke-workload-ocir-policy"
  description    = "Allow dynamic-group oke-workload-dg to read repos in compartment"

  statements = [
    "Allow dynamic-group default/${oci_identity_dynamic_group.oke_workload_dg.name} to read repos in compartment id ${var.compartment_id}"
  ]
}

