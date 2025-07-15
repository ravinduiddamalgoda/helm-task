# Copyright (c) 2024 Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

locals {
  # Create a map of helm operations for easier iteration
  helm_operations_map = {
    for op in var.helm_operations : op.name => op
  }
  
  # Create a map of helm charts for easier iteration
#   helm_charts_map = {
#     for chart in var.helm_charts : chart.name => chart
#   }
}

# Remote-exec resources for each helm operation
resource "null_resource" "helm_operations" {
  for_each = local.helm_operations_map

#   depends_on = [null_resource.helm_charts]

  connection {
    bastion_host        = var.bastion_host_public_ip
    bastion_user        = var.bastion_user
    bastion_private_key = var.bastion_ssh_key
    host                = var.operator_private_ip
    user                = var.operator_user
    private_key         = var.operator_ssh_key
    timeout             = "30m"
    type                = "ssh"
  }

  triggers = merge(
    {
      # Always trigger on operator changes
      operator_id = var.operator_id
    },
    # Include custom triggers from the operation definition
    each.value.triggers
  )

  # Pre-execution setup
  provisioner "remote-exec" {
    inline = [
      "echo 'Starting helm operation: ${each.value.name}'",
      "echo 'Description: ${each.value.description}'",
      "mkdir -p /tmp/helm-operations/${each.value.name}",
      "cd /tmp/helm-operations/${each.value.name}"
    ]
  }

  # Main execution
  provisioner "remote-exec" {
    inline = concat([
      "set -e",  # Exit on any error
      "echo 'Executing commands for: ${each.value.name}'"
    ], each.value.commands, [
      "echo 'Successfully completed: ${each.value.name}'"
    ])
  }



#   # Cleanup on destroy
#   provisioner "remote-exec" {
#     when = destroy
#     inline = [
#       "echo 'Cleaning up helm operation: ${each.value.name}'",
#       "helm uninstall ${each.value.name} --namespace default || true",
#       "helm uninstall ${each.value.name} --namespace kube-system || true",
#       "rm -rf /tmp/helm-operations/${each.value.name} || true"
#     ]
#   }
}

# Helm chart transfer and installation resources
# resource "null_resource" "helm_charts" {
  
#   for_each = local.helm_charts_map

#   connection {
#     bastion_host        = var.bastion_host_public_ip
#     bastion_user        = var.bastion_user
#     bastion_private_key = var.bastion_ssh_key
#     host                = var.operator_private_ip
#     user                = var.operator_user
#     private_key         = var.operator_ssh_key
#     timeout             = "30m"
#     type                = "ssh"
#   }

#   triggers = merge(
#     {
#       # Always trigger on operator changes
#       operator_id = var.operator_id
#       # Trigger on chart file changes
#       chart_content = filebase64sha256(each.value.local_path)
#     },
#     # Include custom triggers from the chart definition
#     each.value.triggers
#   )

#   # Transfer helm chart to operator
#   provisioner "file" {
#     source      = each.value.local_path
#     destination = "/tmp/${each.value.name}-chart"
#   }

#   # Pre-execution setup
#   provisioner "remote-exec" {
#     inline = [
#       "echo 'Starting helm chart installation: ${each.value.name}'",
#       "echo 'Description: ${each.value.description}'",
#       "mkdir -p /home/${var.operator_user}/helm-charts/${each.value.name}",
#       "cp -r /tmp/${each.value.name}-chart/* /home/${var.operator_user}/helm-charts/${each.value.name}/",
#       "rm -rf /tmp/${each.value.name}-chart",
#       "cd /home/${var.operator_user}/helm-charts/${each.value.name}"
#     ]
#   }

#   # Install helm chart
#   provisioner "remote-exec" {
#     inline = concat([
#       "set -e",  # Exit on any error
#       "echo 'Installing helm chart: ${each.value.name}'"
#     ], 
#     # Use custom install command if provided, otherwise use default
#     each.value.install_cmd != null ? [each.value.install_cmd] : [
#       "helm install ${each.value.name} . --namespace ${each.value.namespace} --create-namespace --wait --timeout 10m"
#     ],
#     [
#       "echo 'Successfully installed: ${each.value.name}'",
#       "helm list --namespace ${each.value.namespace}"
#     ])
#   }

#   # Cleanup on destroy
#   provisioner "remote-exec" {
#     when = destroy
#     inline = [
#       "echo 'Cleaning up helm chart: ${each.value.name}'",
#       "helm uninstall ${each.value.name} --namespace ${each.value.namespace} || true",
#       "rm -rf /home/${var.operator_user}/helm-charts/${each.value.name} || true"
#     ]
#   }
# }

# Output the status of helm operations
# resource "null_resource" "helm_status" {
#   depends_on = [null_resource.helm_operations]

#   connection {
#     bastion_host        = var.bastion_host_public_ip
#     bastion_user        = var.bastion_user
#     bastion_private_key = var.bastion_ssh_key
#     host                = var.operator_private_ip
#     user                = var.operator_user
#     private_key         = var.operator_ssh_key
#     timeout             = "10m"
#     type                = "ssh"
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "echo '=== Helm Operations Status ==='",
#       "helm list --all-namespaces",
#       "echo '=== Kubernetes Resources ==='",
#       "kubectl get all --all-namespaces"
#     ]
#   }
# } 