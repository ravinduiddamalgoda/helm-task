# VCN Outputs
output "vcn_id" {
  description = "The OCID of the VCN created by this module."
  value       = module.vcn.vcn_id
}

output "vcn_cidr_block" {
  description = "The CIDR block of the VCN."
  value       = module.vcn.vcn_cidr_block
}

# Gateway Outputs
output "igw_id" {
  description = "The OCID of the Internet Gateway created by this module."
  value       = module.vcn.igw_id
}

output "ngw_id" {
  description = "The OCID of the NAT Gateway created by this module."
  value       = module.vcn.ngw_id
}

output "nat_gateway_id" {
  description = "The OCID of the NAT Gateway (alias for ngw_id)"
  value       = module.vcn.ngw_id
}

output "sgw_id" {
  description = "The OCID of the Service Gateway created by this module."
  value       = module.vcn.sgw_id
}

# Subnet Outputs
output "subnet_availability_domains" {
  description = "Map of subnet names to their availability domains"
  value = { for k, s in module.subnet : k => s.availability_domain }
}

output "route_table_ids" {
  description = "Map of subnet names to their route table OCIDs"
  value = {
    for k, v in module.subnet : k => v.route_table_id
  }
}

# ---------------------------------------------------------------------------
# Map <subnet-name> → OCID so that other stacks (OKE, DB, LB…) can depend on
# the network layer without hard-coding subnet names.
# ---------------------------------------------------------------------------
output "subnet_ids" {
  description = "Map of subnet name → subnet OCID"
  value       = { for name, mod in module.subnet : name => mod.subnet_id }
}

output "subnet_cidrs" {
  description = "Map of subnet name → subnet CIDR block"
  value       = { for name, subnet in local.resolved_subnets : name => subnet.cidr_final }
}

output "nsg_ids" {
  description = "Map of NSG key -> NSG OCID for created Network Security Groups."
  value       = { for key, nsg_mod in module.nsg : key => nsg_mod.nsg_id }
}

output "all_services_cidr" {
  description = "CIDR block for 'All Services in Oracle Services Network' in the current region."
  value       = module.vcn.service_gateway_service_cidr
}

# Debug Outputs for NAT Gateway Troubleshooting
output "debug_nat_gateway_info" {
  description = "Debug information about NAT Gateway creation"
  value = {
    need_ngw = local.need_ngw
    ngw_id_from_vcn = module.vcn.ngw_id
    workers_subnet_exists = contains(keys(module.subnet), "workers")
    workers_gateway_type = try(local.resolved_subnets["workers"].gateway_type, "not found")
  }
}

output "debug_workers_subnet_info" {
  description = "Debug information about workers subnet"
  value = {
    workers_subnet_id = try(module.subnet["workers"].subnet_id, "workers subnet not created")
    workers_route_table_id = try(module.subnet["workers"].route_table_id, "workers route table not created")
    workers_cidr = try(local.resolved_subnets["workers"].cidr_final, "workers cidr not calculated")
  }
}