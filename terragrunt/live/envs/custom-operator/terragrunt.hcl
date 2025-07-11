###############################################################################
# Operator VM – builds a small instance, installs OCI-CLI + kubeconfig
###############################################################################

include "common" {
  # tenancy-wide locals / provider settings
  path   = find_in_parent_folders("env-common.hcl")
  expose = true
}

###############################################################################
# network dependency – we only need the subnet where the VM will live
###############################################################################
dependency "network" {
  config_path = "../core-services/network"

  # Mock outputs for planning phase
  mock_outputs = {
    subnet_ids = {
      bastion = "ocid1.subnet.oc1..mock"
    }
    vcn_id = "ocid1.vcn.oc1..mock"
    vcn_cidr_block = "10.2.0.0/16"
    subnet_availability_domains = {
      bastion = "AD-1"
    }
    igw_id = "ocid1.internetgateway.oc1..mock"
    ngw_id = "ocid1.natgateway.oc1..mock"
    sgw_id = "ocid1.servicegateway.oc1..mock"
    nsg_ids = {}
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "output", "apply"]
}
## bastion dependency
dependency "bastion" {
  config_path = "../core-services/bastion" // Adjust if your operator is in a different path

  mock_outputs = {
    private_ip                        = "10.0.0.100" // Placeholder
    user                              = "opc"        // Placeholder
    ssh_private_key_for_remote_exec   = "mock_ssh_private_key_content_for_bastion" // Placeholder
    kubeconfig_setup_complete_trigger = "mock_kubeconfig_trigger_value_for_bastion"
    id                                = "ocid1.instance.oc1..mockbastion"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}


###############################################################################
# Operator Terraform module
###############################################################################
terraform {
  # path to your reusable module
  source = "../../../../terraform/modules/oci//operator"
}

locals {
  # Attempt to read SSH public key, default to a specific marker if not found
  _raw_ssh_public_key = try(
    file("${get_env("HOME")}/.ssh/id_rsa.pub"),
    get_env("OPERATOR_SSH_PUBLIC_KEY", "__DEFAULT_KEY_NOT_FOUND__")
  )
  
  _final_ssh_public_key = local._raw_ssh_public_key == "__DEFAULT_KEY_NOT_FOUND__" ? null : local._raw_ssh_public_key
}

inputs = {
  # ─── core placement ────────────────────────────────────────────────────

  compartment_id     = try(
                         include.common.locals.compartment_ocid["core-services"],
                         include.common.locals.compartment_ocid
                       )

  # Use the bastion subnet from the network module
  subnet_id          = try(dependency.network.outputs.subnet_ids["operator"], "ocid1.subnet.oc1..mock_direct_fallback_operator") 
  availability_domain = null

  # full shape map expected by the module
  shape = {
    shape            = "VM.Standard.E4.Flex"
    ocpus            = 1
    memory           = 8            # *** use "memory", not memory_in_gbs ***
    boot_volume_size = 50
  }

  # ─── access & users ────────────────────────────────────────────────────
  user               = "opc"
  
  ssh_public_key     = local._final_ssh_public_key
  ssh_private_key    = file(get_env("BASTION_SSH_KEY", ""))


  # ─── required core identifiers ────────────────────────────────────────
  state_id        = "custom-for-services"
  region          = try(include.common.locals.region, get_env("OCI_REGION", "ca-montreal-1"))
  cluster_name    = "oke"                

  # ─── network / DNS / tags ----------------------------------------------------
  
  
  # Use the operator NSG from the network module
  nsg_ids                 = try([dependency.network.outputs.nsg_ids["operator"]], null)
  assign_dns              = false
  tag_namespace           = "koci"
  defined_tags            = {}
  freeform_tags           = include.common.locals.common_tags
  use_defined_tags        = false
  pv_transit_encryption   = false
  # Optional – set to null so Terraform does not send the field
  volume_kms_key_id       = null

  # ─── image & OS -------------------------------------------------------------
  image_id                = "ocid1.image.oc1.ca-montreal-1.aaaaaaaarhsptzukiqy3zeo7e37yxvi2do3gs2xnymlhosz5dwf53dvgymjq"
  operator_image_os_version = "8"

  # ─── kube-related values (bare minimum) -------------------------------------
  kubeconfig           = ""
  kubernetes_version   = "v1.32.1"
  

  # ─── bastion placeholders (none in this setup) ------------------------------
  bastion_host         = dependency.bastion.outputs.public_ip
  bastion_user         = "opc"

  # ─── cloud-init & misc -------------------------------------------------------
  await_cloudinit      = true
  cloud_init           = []           
  timezone             = "UTC"
  upgrade              = true

  # ─── tool install toggles ----------------------------------------------------
  install_cilium            = true
  install_helm              = true
  install_helm_from_repo    = true
  install_istioctl          = true
  install_k9s               = true
  install_kubectx           = true
  install_stern             = true
  install_kubectl_from_repo = true  

  install_oci_cli_from_repo = true


  auto_destroy = true
  terragrunt_dir = get_terragrunt_dir()
} 