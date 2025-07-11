# variables {
#   cni_type = "flannel"
#   vcn_cidr = "10.2.0.0/16"
# }

# run "validate_nsg_resources_created" {
#   command = plan

#   assert {
#     condition = length(module.nsg) > 0
#     error_message = "Expected NSG modules to be created"
#   }

#   assert {
#     condition = length([
#       for nsg_key, nsg_module in module.nsg : nsg_key
#       if contains(["workers", "pods"], nsg_key)
#     ]) > 0
#     error_message = "Expected NSGs for workers and pods to be created"
#   }
# }

# run "validate_cni_specific_rules" {
#   command = plan

#   assert {
#     condition = var.cni_type == "calico" || var.cni_type == "flannel" || var.cni_type == "oci_vcn_native"
#     error_message = "CNI type must be one of: calico, flannel, oci_vcn_native"
#   }

#   assert {
#     condition = can(cidrhost(var.vcn_cidr, 0))
#     error_message = "VCN CIDR must be a valid CIDR block"
#   }
# }

# run "validate_calico_vxlan_rules" {
#   command = plan

#   assert {
#     condition = length(flatten([
#       for nsg_key, nsg_module in module.nsg :
#       [
#         for rule in nsg_module.nsg_rules :
#         rule
#         if contains(["workers"], nsg_key) && var.cni_type == "calico" &&
#         rule.protocol == "17" && rule.direction == "INGRESS" && 
#         (rule.description == "Calico VXLAN 4789" || rule.description == "Flannel VXLAN 4789")
#       ]
#     ])) == 0
#     error_message = "Expected no VXLAN 4789 rules for workers NSG when CNI type is calico (Calico doesn't use VXLAN)"
#   }
# }

# run "validate_flannel_rules_when_enabled" {
#   command = plan

#   assert {
#     condition = length(flatten([
#       for nsg_key, nsg_module in module.nsg :
#       [
#         for rule in nsg_module.nsg_rules :
#         rule
#         if contains(["workers"], nsg_key) && var.cni_type == "flannel" &&
#         rule.protocol == "17" && rule.direction == "INGRESS" && 
#         rule.description == "Flannel VXLAN 4789"
#       ]
#     ])) > 0
#     error_message = "Expected Flannel VXLAN 4789 rule for workers NSG when CNI type is flannel"
#   }

#   assert {
#     condition = length(flatten([
#       for nsg_key, nsg_module in module.nsg :
#       [
#         for rule in nsg_module.nsg_rules :
#         rule
#         if contains(["workers"], nsg_key) && var.cni_type == "flannel" &&
#         rule.protocol == "17" && rule.direction == "INGRESS" && 
#         rule.description == "Flannel UDP 6081"
#       ]
#     ])) > 0
#     error_message = "Expected Flannel UDP 6081 rule for workers NSG when CNI type is flannel"
#   }
# }

# run "validate_no_flannel_rules_for_calico" {
#   command = plan

#   assert {
#     condition = length(flatten([
#       for nsg_key, nsg_module in module.nsg :
#       [
#         for rule in nsg_module.nsg_rules :
#         rule
#         if contains(["workers"], nsg_key) && var.cni_type == "calico" &&
#         rule.protocol == "17" && rule.direction == "INGRESS" &&
#         (rule.description == "Flannel VXLAN 4789" || rule.description == "Flannel UDP 6081")
#       ]
#     ])) == 0
#     error_message = "Expected no Flannel VXLAN rules for workers NSG when CNI type is calico"
#   }
# } 