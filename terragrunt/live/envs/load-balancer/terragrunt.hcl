###############################################################################
# Includes (root & env-common) – give us providers / region / tags / etc.
###############################################################################

include "common" {
  path   = find_in_parent_folders("env-common.hcl")
  expose = true
}

###############################################################################
# Dependencies: we need VCN, subnets, and NSGs from other modules
###############################################################################
dependency "network" {
  config_path = "../core-services/network"

  mock_outputs = {
    vcn_id         = "ocid1.vcn.oc1..mocknetwork"
    subnet_ids = {
      pub_lb = "ocid1.subnet.oc1..mockpubliclb"
      int_lb = "ocid1.subnet.oc1..mockinternallb"
    }
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
}

dependency "oke" {
  config_path = "../core-services/oke"

  mock_outputs = {
    vcn_id         = "ocid1.vcn.oc1..mocknetwork"
    subnet_ids = {
      pub_lb = "ocid1.subnet.oc1..mockpubliclb"
      int_lb = "ocid1.subnet.oc1..mockinternallb"
    }
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
}

dependency "security" {
  config_path = "../security"

  mock_outputs = {
    lb_nsg_id = "ocid1.networksecuritygroup.oc1..mocklbnsg"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
}

###############################################################################
# Locals – compute values we need
###############################################################################
locals {
  env_name = "${include.common.locals.name_prefix}-${include.common.locals.env}"
  
  # Load balancer configuration
  lb_shape = "100Mbps"  # or "10Mbps", "100Mbps", "400Mbps", "8000Mbps"
  lb_is_private = false  # Set to true for private load balancer
  

  backend_ips = try(dependency.oke.outputs.worker_node_private_ips, ["10.2.68.10", "10.2.68.11"]) 
  
  common_tags = include.common.locals.common_tags
}

###############################################################################
# Terraform configuration

terraform {
  source = "../../../../terraform/modules/oci/loadbalancer"
}

###############################################################################
# Inputs - Pass variables to the load balancer module
###############################################################################
inputs = {
  # Required variables
  compartment_id = include.common.locals.compartment_ocid
  env_name       = local.env_name
  shape          = local.lb_shape
  vcn_id         = dependency.network.outputs.vcn_id
  
  # Subnet configuration - use pub_lb for public LB, int_lb for private LB
  subnet_ids = local.lb_is_private ? [dependency.network.outputs.subnet_ids.int_lb] : [dependency.network.outputs.subnet_ids.pub_lb]
  
  # Load balancer type
  is_private = local.lb_is_private
  
  # Backend configuration
  backend_ips = try(dependency.oke.outputs.worker_node_private_ips, ["10.2.68.10", "10.2.68.11"])  # Example backend IPs from workers subnet - update as needed
  backend_set_name = "app-backendset"
  
  # NSG configuration
  nsg_ids = local.lb_is_private ? [dependency.network.outputs.nsg_ids.int_lb] : [dependency.network.outputs.nsg_ids.pub_lb]
  
  
  certificate_id = ""  # Set this if you have an SSL certificate
  certificate_name = "default-cert"
  
  # WAF configuration 
  waf_policy_id = dependency.security.outputs.waf_policy_id 
} 