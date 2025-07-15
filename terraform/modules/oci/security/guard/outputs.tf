output "security_zone_id" {  
  description = "OCID of the Cloud Guard Security Zone" 
  value       = var.enabled ? oci_cloud_guard_security_zone.network_security_zone[0].id : null
}

output "security_zone_display_name" {
  description = "Display name of the Cloud Guard Security Zone"
  value       = var.enabled ? oci_cloud_guard_security_zone.network_security_zone[0].display_name : null
}

output "cloud_guard_configuration_id" {
  description = "OCID of the Cloud Guard configuration"
  value       = var.enabled ? oci_cloud_guard_cloud_guard_configuration.enable_cloud_guard[0].id : null
}

output "security_zone_recipe_id" {
  description = "OCID of the Security Zone recipe being used"
  value       = var.enabled ? data.oci_cloud_guard_security_recipes.security_zone_recipes[0].security_recipe_collection[0].items[0].id : null
}

output "enabled" {
  description = "Whether Cloud Guard and Security Zone are enabled"
  value       = var.enabled
} 