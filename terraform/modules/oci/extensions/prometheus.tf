# Copyright (c) 2023 Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

locals {
  prometheus_helm_crds_file     = join("/", [local.yaml_manifest_path, "prometheus.crds.yaml"])
  prometheus_helm_manifest_file = join("/", [local.yaml_manifest_path, "prometheus.manifest.yaml"])
  prometheus_helm_values_file   = join("/", [local.yaml_manifest_path, "prometheus.values.yaml"])
  prometheus_helm_crds          = sensitive(one(data.helm_template.prometheus[*].crds))
  prometheus_helm_manifest      = sensitive(one(data.helm_template.prometheus[*].manifest))

  prometheus_helm_values_yaml = jsonencode(var.prometheus_helm_values)
}

data "helm_template" "prometheus" {
  count        = var.prometheus_install ? 1 : 0
  chart        = "kube-prometheus-stack"
  repository   = "https://prometheus-community.github.io/helm-charts"
  version      = var.prometheus_helm_version
  kube_version = var.kubernetes_version

  name             = "prometheus"
  namespace        = var.prometheus_namespace
  create_namespace = true
  include_crds     = true
  skip_tests       = true
  values = concat(
    [local.prometheus_helm_values_yaml],
    [for path in var.prometheus_helm_values_files : file(path)],
  )

  set {
    name  = "podSecurityPolicy.enabled"
    value = "false"
  }

  dynamic "set" {
    for_each = var.prometheus_helm_values
    iterator = helm_value
    content {
      name  = helm_value.key
      value = helm_value.value
    }
  }

  lifecycle {
    precondition {
      condition = alltrue([for path in var.prometheus_helm_values_files : fileexists(path)])
      error_message = format("Missing Helm values files in configuration: %s",
        jsonencode([for path in var.prometheus_helm_values_files : path if !fileexists(path)])
      )
    }
  }
}

output "prometheus_server_manifest_path_yaml" {  
  value = local.yaml_manifest_path
}

resource "null_resource" "prometheus" {
  count = var.prometheus_install ? 1 : 0

  triggers = {
    helm_version = var.prometheus_helm_version
    crds_md5     = try(md5(join("\n", local.prometheus_helm_crds)), null)
    manifest_md5 = try(md5(local.prometheus_helm_manifest), null)
    reapply      = var.prometheus_reapply ? uuid() : null
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

# kube-config
export HOME=/home/${var.operator_user}
mkdir -p "$HOME/.kube"
until kubectl version --client >/dev/null 2>&1; do sleep 10; done
EOF
)"
EOT
,
      "mkdir -p ${local.yaml_manifest_path}",
    ]
  }

  provisioner "file" {
    content     = join("\n", local.prometheus_helm_crds)
    destination = local.prometheus_helm_crds_file
  }

  provisioner "file" {
    content     = local.prometheus_helm_manifest
    destination = local.prometheus_helm_manifest_file
  }

  provisioner "file" {
    content     = local.prometheus_helm_values_yaml
    destination = local.prometheus_helm_values_file
  }
  provisioner "remote-exec" {
    inline = concat(
      [for c in compact([
        (contains(["kube-system", "default"], var.prometheus_namespace) ? null
        : format(local.kubectl_create_missing_ns, var.prometheus_namespace)),
        format(local.kubectl_apply_server_file, local.prometheus_helm_crds_file),
        format(local.kubectl_apply_server_file, local.prometheus_helm_manifest_file),
      ]) : format(local.output_log, c, "prometheus")]
    )
  }
}
