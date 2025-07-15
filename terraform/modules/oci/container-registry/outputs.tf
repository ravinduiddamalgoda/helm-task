output "repository_id" {
  description = "OCID of the container repository"
  value       = oci_artifacts_container_repository.main.id
}

output "repository_name" {
  description = "Name of the container repository"
  value       = oci_artifacts_container_repository.main.display_name
}

