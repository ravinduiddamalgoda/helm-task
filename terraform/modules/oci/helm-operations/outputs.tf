# Copyright (c) 2024 Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

output "helm_operations_status" {
  description = "Status of helm operations execution"
  value = {
    operations_count = length(var.helm_operations)
    operations_names = [for op in var.helm_operations : op.name]
    state_id         = var.state_id
    region           = var.region
  }
}

output "operator_connection_info" {
  description = "Connection information for the operator instance"
  value = {
    private_ip = var.operator_private_ip
    user       = var.operator_user
    bastion_host = var.bastion_host_public_ip
    bastion_user = var.bastion_user
  }
  sensitive = false
}

output "helm_operations_details" {
  description = "Detailed information about configured helm operations"
  value = [
    for op in var.helm_operations : {
      name        = op.name
      description = op.description
      commands_count = length(op.commands)
      triggers    = op.triggers
    }
  ]
}

# output "helm_charts_details" {
#   description = "Detailed information about configured helm charts"
#   value = [
#     for chart in var.helm_charts : {
#       name        = chart.name
#       description = chart.description
#       local_path  = chart.local_path
#       namespace   = chart.namespace
#       values_file = chart.values_file
#       triggers    = chart.triggers
#     }
#   ]
# }

# output "helm_charts_status" {
#   description = "Status of helm charts installation"
#   value = {
#     charts_count = length(var.helm_charts)
#     charts_names = [for chart in var.helm_charts : chart.name]
#     state_id     = var.state_id
#     region       = var.region
#   }
# } 