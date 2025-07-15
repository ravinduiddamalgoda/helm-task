###############################################################################
# Bastion (Tailscale) layer – depends on network outputs
###############################################################################

# ─── inherit env-common ──────────────────────────────────────────────────
include "common" {
  path   = find_in_parent_folders("env-common.hcl")
  expose = true
}

# ─── dependency: network (subnets, NSGs, VCN CIDR) ──────────────────────
dependency "network" {
  config_path = "../network"

  # Use mock values until the network layer has been applied
  mock_outputs = {
    subnet_ids     = { bastion = "ocid1.subnet.oc1..mock" }
    nsg_ids        = { bastion = "ocid1.networksecuritygroup.oc1..mock" }
    vcn_cidr_block = "10.2.0.0/16"
  }
}

###############################################################################
# Terraform module
###############################################################################
terraform {
  source = "../../../../../terraform/modules/oci/bastion"
}

locals {
  # read the auth-key from shell env at plan/apply time
  tailscale_auth_key = get_env("TAILSCALE_AUTH_KEY", "")

  # ---- defaults for required module variables -------------------
  # Change these if your tenancy uses different values
  timezone            = "UTC"
  tag_namespace       = "koci"                       
}

inputs = {
  # ── mandatory IDs ─────────────────────────────────────────────────────
  # Access the compartment that belongs to this environment
  compartment_id        = try(
                            include.common.locals.compartment_ocid["core-services"],
                            include.common.locals.compartment_ocid
                          )

  # Most OCI modules call this variable "tenancy_id"
  tenancy_id            = include.common.locals.tenancy_ocid
  state_id              = "core-services"

  # Name overrides
  instance_display_name = "${include.common.locals.env}-bastion"   
  hostname_label        = "core-services-bastion"                  

  # place the VM in the bastion subnet / NSG created by the network layer
  subnet_id = dependency.network.outputs.subnet_ids["bastion"]
  nsg_ids   = [ dependency.network.outputs.nsg_ids["bastion"] ]

  # advertise the full VCN so internal services are reachable over TS
  vcn_cidrs = [ dependency.network.outputs.vcn_cidr_block ]

  # ── bastion / tailscale switches ──────────────────────────────────────
  is_public        = true
  assign_dns       = true
  await_cloudinit  = true
  tailscale_auth_key  = local.tailscale_auth_key
  tailscale_exit_node = false   # set true if this host should be an exit-node

  # ── image / shape (auto-selects latest Oracle Linux) ──────────────────
  bastion_image_os_version = "8"
  shape = {
    shape            = "VM.Standard.E4.Flex"
    ocpus            = 1
    memory_in_gbs    = 4
    boot_volume_size = 50
  }

  # ── SSH (leave empty to disable) ───────────────────────────────────────
  # ssh_public_key  = file("~/.ssh/oci_bastion_ed25519.pub")  

  # ssh_private_key = file(get_env("BASTION_SSH_KEY", ""))

  ssh_public_key  = include.common.locals.bastion_ssh_public_key != "" ? include.common.locals.bastion_ssh_public_key : ""
  ssh_private_key = include.common.locals.bastion_ssh_private_key != "" ? include.common.locals.bastion_ssh_private_key : ""

  defined_tags   = {}
  freeform_tags  = include.common.locals.common_tags

  # ── values that were missing (all are required by the module) ──
  timezone            = local.timezone
  upgrade             = true          
  user                = "kociadmin"     

  tag_namespace   = local.tag_namespace
  use_defined_tags = false            
} 