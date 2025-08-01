include "common" {
  path   = find_in_parent_folders("env-common.hcl")
  expose = true
}

terraform {
  source = "."

  # This layer only queries data, so no real module source is needed,
  # but you can point to a tiny "info-only" module if you like.
}

dependency "oke" {
  config_path = "../oke"
}

inputs = {
  node_pool_ids = dependency.oke.outputs.node_pool_ids
}

generate "data_node_pools" {
  path      = "data-node-pools.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOT
    variable "node_pool_ids" {
        type = list(string)
    }

    data "oci_containerengine_node_pool" "np_details" {
        for_each     = toset(var.node_pool_ids)
        node_pool_id = each.value
    }

    # output "worker_node_private_ips" {
    #     value = {
    #         for npid, np in data.oci_containerengine_node_pool.np_details :
    #         npid => [ for node in np.nodes : node.private_ip ]
    #     }
    # }
    output "worker_node_private_ips" {
        value = flatten(values(data.oci_containerengine_node_pool.np_details)[*].nodes[*].private_ip)
    }

  EOT
}
