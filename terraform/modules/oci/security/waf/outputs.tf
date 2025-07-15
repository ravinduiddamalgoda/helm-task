output "waf_policy_id" {
  description = "The OCID of the WAF policy"
  value       = oci_waf_web_app_firewall_policy.this.id
}

output "waf_policy_display_name" {
  description = "The display name of the WAF policy"
  value       = oci_waf_web_app_firewall_policy.this.display_name
}

output "waf_policy_compartment_id" {
  description = "The compartment OCID where the WAF policy is created"
  value       = oci_waf_web_app_firewall_policy.this.compartment_id
} 