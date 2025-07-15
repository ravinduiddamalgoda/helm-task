###############################################################################
# Helm Operations – Remote exec for helm install/update from operator
###############################################################################

include "common" {
  # tenancy-wide locals / provider settings
  path   = find_in_parent_folders("env-common.hcl")
  expose = true
}

###############################################################################
# Dependencies
###############################################################################
dependency "operator" {
  config_path = "../custom-operator"

  # Mock outputs for planning phase
  mock_outputs = {
    private_ip                        = "10.0.0.100"
    user                              = "opc"
    ssh_private_key_for_remote_exec   = "mock_ssh_private_key_content"
    kubeconfig_setup_complete_trigger = "mock_kubeconfig_trigger_value"
    id                                = "ocid1.instance.oc1..mockoperator"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "bastion" {
  config_path = "../core-services/bastion"

  mock_outputs = {
    public_ip                         = "10.0.0.1"
    private_ip                        = "10.0.0.100"
    user                              = "opc"
    ssh_private_key_for_remote_exec   = "mock_ssh_private_key_content_for_bastion"
    kubeconfig_setup_complete_trigger = "mock_kubeconfig_trigger_value_for_bastion"
    id                                = "ocid1.instance.oc1..mockbastion"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

###############################################################################
# Helm Operations Terraform module
###############################################################################
terraform {
  # path to your reusable module
  source = "../../../../terraform/modules/oci//helm-operations"
}

inputs = {
  # ─── core placement ────────────────────────────────────────────────────
  compartment_id = include.common.locals.compartment_ocid
  

  # ─── operator connection details ────────────────────────────────────────
  operator_private_ip = dependency.operator.outputs.private_ip
  operator_user       = "opc"
  operator_ssh_key    = dependency.operator.outputs.ssh_private_key_for_remote_exec
  operator_id         = dependency.operator.outputs.id

  # ─── bastion connection details (if needed for SSH tunneling) ───────────
  bastion_host_public_ip        = dependency.bastion.outputs.public_ip
  bastion_user        = "opc"
  bastion_ssh_key     = dependency.operator.outputs.ssh_private_key_for_remote_exec

  # ─── helm operations configuration ──────────────────────────────────────
  helm_operations = [
    {
      name        = "setup-helm-repos"
      description = "Setup common helm repositories"
      commands = [
        "helm repo add bitnami https://charts.bitnami.com/bitnami",
        "helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx",
        "helm repo add jetstack https://charts.jetstack.io",
        "helm repo update"
      ]
      triggers = {
        repos_version = "1.0.0"
      }
    }
  ]

  # ─── helm charts configuration ──────────────────────────────────────────
#   helm_charts = [
#     {
#       name        = "helm-task"
#       description = "Install helm-task chart from local directory"
#       local_path  = "../../../../helm-task"  # Path relative to terragrunt file
#       namespace   = "default"
#       triggers = {
#         chart_version = "1.0.0"  # Change this to trigger re-execution
#       }
#     }
#   ]

  # ─── required core identifiers ──────────────────────────────────────────
  state_id = "helm-operations"
  region   = try(include.common.locals.region, get_env("OCI_REGION", "ca-montreal-1"))

  # ─── tags ───────────────────────────────────────────────────────────────
  tag_namespace    = "koci"
  defined_tags     = {}
  freeform_tags    = include.common.locals.common_tags
  use_defined_tags = false
} 