# Copyright (c) 2017, 2023 Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

locals {
  metrics_server_enabled       = var.metrics_server_install && var.expected_node_count > 0
  metrics_server_manifest      = sensitive(one(data.helm_template.metrics_server[*].manifest))
  metrics_server_manifest_path = join("/", [local.yaml_manifest_path, "metrics_server.manifest.yaml"])
}

data "helm_template" "metrics_server" {
  count        = local.metrics_server_enabled ? 1 : 0
  chart        = "metrics-server"
  repository   = "https://kubernetes-sigs.github.io/metrics-server"
  version      = var.metrics_server_helm_version
  kube_version = var.kubernetes_version

  name             = "metrics-server"
  namespace        = var.metrics_server_namespace
  create_namespace = true
  include_crds     = true
  skip_tests       = true
  values = length(var.metrics_server_helm_values_files) > 0 ? [
    for path in var.metrics_server_helm_values_files : file(path)
  ] : null

  dynamic "set" {
    for_each = var.metrics_server_helm_values
    iterator = helm_value
    content {
      name  = helm_value.key
      value = helm_value.value
    }
  }

  lifecycle {
    precondition {
      condition = alltrue([for path in var.metrics_server_helm_values_files : fileexists(path)])
      error_message = format("Missing Helm values files in configuration: %s",
        jsonencode([for path in var.metrics_server_helm_values_files : path if !fileexists(path)])
      )
    }
  }
}

output "metric_server_manifest_path_yaml" {  
  value = local.yaml_manifest_path
}

resource "null_resource" "metrics_server" {
  count = local.metrics_server_enabled ? 1 : 0

  triggers = {
    manifest_md5 = try(md5(local.metrics_server_manifest), null)
  }

  connection {
    bastion_host        = var.bastion_host_public_ip
    bastion_user        = var.bastion_user
    bastion_private_key = length(trimspace(var.ssh_private_key)) > 0 ? var.ssh_private_key : null
    host                = var.operator_host
    user                = var.operator_user
    private_key         = length(trimspace(var.ssh_private_key)) > 0 ? var.ssh_private_key : null
    timeout             = "40m"
    type                = "ssh"
  }

  provisioner "remote-exec" {
    inline = [<<EOT
    sudo bash -c "$(cat <<'EOF'
set -eu
export OCI_CLI_AUTH=instance_principal
export PATH=$PATH:/usr/local/bin

# OCI CLI
if ! command -v oci >/dev/null 2>&1; then
  curl -Ls https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh -o /tmp/install-oci.sh
  bash /tmp/install-oci.sh --accept-all-defaults --install-dir /usr/local/bin --exec-dir /usr/local/bin
fi

# kubectl
if ! command -v kubectl >/dev/null 2>&1; then
  curl -sL https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl
  chmod +x /usr/local/bin/kubectl
fi

# kube-config already present
export HOME=/home/${var.operator_user}
export KUBECONFIG="$HOME/.kube/config"
until kubectl version --client >/dev/null 2>&1; do sleep 10; done
EOF
)"
EOT
,
      "mkdir -p ${local.yaml_manifest_path}",
    ]
  }

  
  provisioner "file" {
    content     = local.metrics_server_manifest
    destination = local.metrics_server_manifest_path
  }

  provisioner "remote-exec" {   ##hardcode
    inline = compact([
      # Clean up any existing metrics-server deployment to avoid immutable selector errors
      "kubectl delete deployment metrics-server -n ${var.metrics_server_namespace} --ignore-not-found=true || true",
      "kubectl delete service metrics-server -n ${var.metrics_server_namespace} --ignore-not-found=true || true",
      "kubectl delete apiservice v1beta1.metrics.k8s.io --ignore-not-found=true || true",
      # Wait a moment for cleanup to complete
      "sleep 5",
      (contains(["kube-system", "default"], var.metrics_server_namespace) ? null
      : format(local.kubectl_create_missing_ns, var.metrics_server_namespace)),
      format(local.kubectl_apply_server_file, local.metrics_server_manifest_path),
    ])
  }

}
