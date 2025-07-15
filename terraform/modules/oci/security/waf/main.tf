resource "oci_waf_web_app_firewall_policy" "this" {
  compartment_id = var.compartment_id
  display_name   = "${var.env_name}-waf-policy"

  request_protection {
    dynamic "rules" {
      for_each = var.waf_rules
      content {
        name        = rules.value.name
        action_name = rules.value.action_name
        condition   = rules.value.condition
        type        = "PROTECTION_CAPABILITY"

        protection_capabilities {
          key     = rules.value.capability_key
          version = "1.0"
        }
      }
    }
  }

  freeform_tags = var.freeform_tags
}
