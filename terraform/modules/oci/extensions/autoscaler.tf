# Copyright (c) 2022, 2023 Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

# https://github.com/kubernetes/autoscaler/tree/master/charts/cluster-autoscaler
# https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengautoscalingclusters.htm

locals {
  # Active worker pools that should be managed by the cluster autoscaler
  worker_pools_autoscaling = { for k, v in var.worker_pools : k => v if tobool(lookup(v, "autoscale", false)) }

  # Whether to enable cluster autoscaler deployment based on configuration, active nodes, and autoscaling pools
  cluster_autoscaler_enabled = alltrue([
    var.cluster_autoscaler_install,
    var.expected_node_count > 0,
    var.expected_autoscale_worker_pools > 0,
  ])

  # Templated Helm manifest values
  cluster_autoscaler_manifest      = sensitive(one(data.helm_template.cluster_autoscaler[*].manifest))
  cluster_autoscaler_manifest_path = join("/", [local.yaml_manifest_path, "cluster_autoscaler.yaml"])
  cluster_autoscaler_defaults = {
    "cloudProvider"                              = "oci-oke",
    "extraArgs.logtostderr"                      = "true",
    "extraArgs.v"                                = "4",
    "extraArgs.stderrthreshold"                  = "info",
    "extraArgs.max-node-provision-time"          = "25m",
    "extraArgs.scale-down-unneeded-time"         = "2m",
    "extraArgs.unremovable-node-recheck-timeout" = "5m",
    "extraArgs.balance-similar-node-groups"      = "true",
    "extraArgs.balancing-ignore-label"           = "displayName",
    "extraArgs.balancing-ignore-label"           = "hostname",
    "extraArgs.balancing-ignore-label"           = "internal_addr",
    "extraArgs.balancing-ignore-label"           = "oci.oraclecloud.com/fault-domain",
    "extraEnv.OCI_REGION"                        = var.region,
    "extraEnv.OCI_USE_INSTANCE_PRINCIPAL"        = "true",
    "extraEnv.OKE_USE_INSTANCE_PRINCIPAL"        = "true",
    "extraEnv.OCI_SDK_APPEND_USER_AGENT"         = "oci-oke-cluster-autoscaler",
    "image.repository"                           = "iad.ocir.io/oracle/oci-cluster-autoscaler",
    "image.tag"                                  = "1.26.2-7",
  }
}

data "helm_template" "cluster_autoscaler" {
  count        = local.cluster_autoscaler_enabled ? 1 : 0
  chart        = "cluster-autoscaler"
  repository   = "https://kubernetes.github.io/autoscaler"
  version      = var.cluster_autoscaler_helm_version
  kube_version = var.kubernetes_version

  name             = "cluster-autoscaler"
  namespace        = var.cluster_autoscaler_namespace
  create_namespace = true
  include_crds     = true
  skip_tests       = true

  values = length(var.cluster_autoscaler_helm_values_files) > 0 ? [
    for path in var.cluster_autoscaler_helm_values_files : file(path)
  ] : null

  set {
    name  = "nodeSelector.oke\\.oraclecloud\\.com/cluster_autoscaler"
    value = "allowed"
  }

  dynamic "set" {
    for_each = merge(local.cluster_autoscaler_defaults, var.cluster_autoscaler_helm_values)
    iterator = helm_value
    content {
      name  = helm_value.key
      value = helm_value.value
    }
  }

  dynamic "set" {
    for_each = { for k, v in local.worker_pools_autoscaling : k => v if contains(keys(v), "id") }
    iterator = pool
    content {
      name  = "autoscalingGroups[${index(keys(local.worker_pools_autoscaling), pool.key)}].name"
      value = pool.value.id
    }
  }

  dynamic "set" {
    for_each = local.worker_pools_autoscaling
    iterator = pool
    content {
      name  = "autoscalingGroups[${index(keys(local.worker_pools_autoscaling), pool.key)}].minSize"
      value = lookup(pool.value, "min_size", lookup(pool.value, "size"))
    }
  }

  dynamic "set" {
    for_each = local.worker_pools_autoscaling
    iterator = pool
    content {
      name  = "autoscalingGroups[${index(keys(local.worker_pools_autoscaling), pool.key)}].maxSize"
      value = lookup(pool.value, "max_size", lookup(pool.value, "size"))
    }
  }

  lifecycle {
    precondition {
      condition = alltrue([for path in var.cluster_autoscaler_helm_values_files : fileexists(path)])
      error_message = format("Missing Helm values files in configuration: %s",
        jsonencode([for path in var.cluster_autoscaler_helm_values_files : path if !fileexists(path)])
      )
    }
  }
}
output "Auto_scaler_manifest_path_yaml" {  
  value = local.yaml_manifest_path
}

resource "null_resource" "cluster_autoscaler" {
  count = local.cluster_autoscaler_enabled ? 1 : 0

  triggers = {
    manifest_md5 = try(md5(local.cluster_autoscaler_manifest), null)
    cluster_id   = var.cluster_id
    kubeconfig_dep = sha1(jsonencode(var.kubeconfig_dependency))
  }

  connection {
    type        = "ssh"
    host        = var.remote_host_ip
    user        = var.remote_host_user
    private_key = var.remote_host_private_key
    bastion_host = var.bastion_host_public_ip     # Public IP of bastion
    bastion_user = var.remote_host_user
    bastion_private_key = var.remote_host_private_key
    agent       = false
    timeout     = "10m"
  }

  

  provisioner "remote-exec" {
    inline = [
      "set -ex",
      "export PATH=$HOME/bin:$PATH",
      "export KUBECONFIG=/home/opc/.kube/config",  #####
      "chmod +r /home/opc/.kube/config",
      "export OCI_CLI_AUTH=instance_principal",
      # Delete the existing release if it exists
      "if helm list -n kube-system | grep -q cluster-autoscaler; then helm uninstall cluster-autoscaler -n kube-system; fi",
      "echo 'Deploying Cluster Autoscaler...'",
      "helm repo add autoscaler https://kubernetes.github.io/autoscaler || echo 'Autoscaler repo may already be added'",
      "helm repo update",
      "helm upgrade --install cluster-autoscaler autoscaler/cluster-autoscaler \\",
      "  --namespace kube-system \\",
      "  --set autoDiscovery.clusterName=oke-oke \\",
      "  --set rbac.create=true \\",
      "  --set cloudProvider=oci \\",
      "  --set extraEnv.OCI_USE_INSTANCE_PRINCIPAL=true \\",
      "  --wait --timeout 5m"
    ]
  }

  provisioner "remote-exec" {
    inline = ["mkdir -p ${local.yaml_manifest_path}"]
  }

  provisioner "file" {
    content     = local.cluster_autoscaler_manifest
    destination = local.cluster_autoscaler_manifest_path
  }

  provisioner "remote-exec" {
    inline = ["kubectl apply -f ${local.cluster_autoscaler_manifest_path}"]
  }
}

output "worker_pools_pools_list2" {
  value = local.worker_pools_autoscaling
  description = "List of autoscaling worker pools with id, min_size, and max_size"
  sensitive = false
}

