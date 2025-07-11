output "cluster_id" {
  description = "OCID of the OKE cluster"
  value       = module.oke_cluster.id
}

output "node_pool_ids" {
  description = "List of node-pool OCIDs"
  value       = [for np in oci_containerengine_node_pool.node_pool : np.id]
}

output "app_nodes_nsg_id" {
  description = "OCID of the app nodes NSG"
  value       = module.app_nodes_nsg.nsg_id
}

output "kube_api_nsg_id" {
  description = "OCID of the kube-api NSG"
  value       = module.kube_api_nsg.nsg_id
}

output "kubernetes_endpoint" {
  description = "Kubernetes API private endpoint"
  value       = module.oke_cluster.private_endpoint
}

output "kubeconfig_setup_complete_trigger" {
  description = "ID(s) of the null_resource that creates the kubeconfig. Empty list when generate_kubeconfig=false."
  value       = null_resource.create_kubeconfig[*].id   # returns [] or ["<id>"]
} 

output "user" {
  description = "The SSH user for the operator instance."
  value       = var.user
}



output "worker_node_private_ips" {  
  description = "List of worker node private IP addresses"
  value       = data.oci_core_instances.worker_nodes.instances[*].private_ip
}

# output "worker_nodes_testing" {  
#   description = "List of worker node private IP addresses"
#   value       = data.oci_core_instances.worker_nodes
# }

# output "worker_nodes_instances" {  
#   description = "List of worker node private IP addresses"
#   value       = data.oci_core_instances.worker_nodes.instances
# }


# output "node_private_ips" {
#   description = "A list of private IP addresses for all nodes in the specified node pool."
#   # The 'nodes' attribute is a list of objects, each representing a node.
#   # We use a 'for' expression to iterate over this list and extract the 'private_ip' attribute.
#   value = [for node in data.oci_containerengine_node_pool.example_node_pool.nodes : node.private_ip]
# }
output "nodes_private_ips_workers" {
  value = {
    for k, v in data.oci_core_vnic.vnics :
    k => v.private_ip
  }
}
