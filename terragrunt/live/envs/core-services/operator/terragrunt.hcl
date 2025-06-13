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
  config_path = "../network"

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

###############################################################################
# Operator Terraform module
###############################################################################
terraform {
  # path to your reusable module
  source = "../../../../../terraform/modules/oci//operator"
}

locals {
  # Attempt to read SSH public key, default to a specific marker if not found
  _raw_ssh_public_key = try(
    file("${get_env("HOME")}/.ssh/id_rsa.pub"),
    get_env("OPERATOR_SSH_PUBLIC_KEY", "__DEFAULT_KEY_NOT_FOUND__")
  )
  # Set to null if marker is present (meaning no key was found), otherwise use the key
  _final_ssh_public_key = local._raw_ssh_public_key == "__DEFAULT_KEY_NOT_FOUND__" ? null : local._raw_ssh_public_key
}

inputs = {
  # ─── core placement ────────────────────────────────────────────────────
  # If compartment_ocid is a map use the env-specific key;
  # otherwise fall back to the plain string value.
  compartment_id     = try(
                         include.common.locals.compartment_ocid["core-services"],
                         include.common.locals.compartment_ocid
                       )

  # Use the bastion subnet from the network module
  subnet_id          = try(dependency.network.outputs.subnet_ids["bastion"], "ocid1.subnet.oc1..mock_direct_fallback_operator")
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
  # first try to read the default pub-key; if it is missing,
  # fall back to the OPERATOR_SSH_PUBLIC_KEY env-var (or "")
  ssh_public_key     = local._final_ssh_public_key
  ssh_private_key    = <<KEY
-----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEAre6se8tfHhU5AjKjlJDYrOBcwJQNaAgoTMoOQrSIOJTn71Mh
v6OGMb+LzwEe8vOY124e2OC1+M9UL1N9Cqd4cG+xWCoFxgp652ahtMegJpYan5iP
1CM6VySi6hr8yPSCTRQYStfWypzCKiZbp6WeXAM35g0+6auAnzJOhmNT0EXd4wzh
MDE2mkXZtH0Jv+pDWsZZE/QrA/onFI4r8JOw6LElJoQTALKO1zQ7Z/isi7RGyhWQ
uoiF1rl5u5JIg+j2FOhRr34R66Ws/7bRA3+ra5kTqLKXbKr+WmiAiGu4+glgMNO+
zIh63ZxmKgGQgtxCsygz3NqoqrXSxJAMrzNY0QIDAQABAoIBAAqosQTQIIbfLZRz
Jn+tBb5IbJ63o/+vWkrkag3P8vYmt/T8bvnHy2pCjw6TRsKER6ZSHw1S7gvupr3U
u7m6rCCV07QvtRVfIIuMSFYkEq4yrjSAHLZXJ1TeT6aRm1K0W0TeeaOiiQz3INYE
7kJ+nY8NenA8eRHIWxRGeLX3IdSGTZV6w2QKIRRJ73mDKdeoWq82c4CePKXOSNmJ
wlpVLeSpN3aqUWu2kHW9sG6zIiEdcB4X7Sx1ooEW8z1kBt5hi52eJz3W/7LZMLYV
w7Dz2J+QjhGEg3uejdHdg6nMR099d6amG6WMBBnav8mOEwNSBRVu41qU9KMr3XaX
YthLk4ECgYEA6VyKAO+A+Sy19AlS/tuzn0F6aRYIbWS1DW+UoXfu/hb8xkm7myNY
1zdqDulgnvtp+WimaX5O+/c8/MGbc/W21M92TFeRU121sbChE+ZaBoPHGDSq0UkV
nqCHGv9ML8ftN0DyyXQ6j9DU/mgDO04Yzzi441usgTkpLkC8AcAof6ECgYEAvs46
ywob4AVL9tmjen9c0OeN1P49gOf0eUiC7P4+F8d7qjpSMPNjzygzt8quPupN44ld
et7riare9opupZ200LVHIdH5PDKirQiGbmVQwpk/fy94vTDa72tk2EP72ZaELSLz
YGuHIdwK4dGF9Bpzx+gB6qHkP4+7CZxtDqKXCzECgYEArCbrW9NTxv434Ka8Rm0X
boXkYv+xCdqAQkAtWozajzGwGiusrb7+vA4SPJvn/oCkZizQjwRyCikTIbdGEd6T
mRzPPXRgLir0bfhKbB7EDQhL6Mx5s1kCDPqJkN4De0A2/Er6kKkgxpWde2yJ7cco
QD6tDnTDprTfb1KsH3J9reECgYEAkDqNoJrklUMLt+2tsFQD0fmmcYE49m7fkqoo
JYLNZuYoaXWqWUwxfw7RgTVY3z/3Xm6gVdeZzbd20H+1wcTjP/w3Z64zqrhP1WIj
U+GL2X1DzR0SNFhwthfE4+EHx+MJyKCpvZGqVQLiyu25RtqT+GE8yaJUSWOZK1ut
6Cko6ZECgYEAiM1DJ4psj3NpCc23hOv7w8Kb/0AjvAMhJtUEy2yU5b4r1NgQ5lzb
KJXFFcrBhFYUYZGUNQoRi3WxtByy4dDNtZ/dZBzt/XLr6NKEQAyFjhEpRtfgnFPq
2VtshPmaeQbINW3hmjtK5ebcBf10Fxv0WNLnRVKzs7sJ6+1kk/Xcss8=
-----END RSA PRIVATE KEY-----
KEY
  
  # get_env("BASTION_SSH_KEY", "")   # same key you use from Terragrunt
                                                         # mark BASTION_SSH_KEY in your env

  # ─── required core identifiers ────────────────────────────────────────
  state_id        = "core-services"
  region          = try(include.common.locals.region, get_env("OCI_REGION", "ca-montreal-1"))
  cluster_name    = "core-services"                 # arbitrary, but required

  # ─── network / DNS / tags ----------------------------------------------------
  # When you have no NSGs, use null so the field is not sent to OCI.
  nsg_ids                 = null
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
  kubernetes_version   = "1.29.1"

  # ─── bastion placeholders (none in this setup) ------------------------------
  bastion_host         = ""
  bastion_user         = ""

  # ─── cloud-init & misc -------------------------------------------------------
  await_cloudinit      = false
  cloud_init           = []           # list(map(string)) as required
  timezone             = "UTC"
  upgrade              = true

  # ─── tool install toggles ----------------------------------------------------
  install_cilium            = false
  install_helm              = false
  install_helm_from_repo    = false
  install_istioctl          = false
  install_k9s               = false
  install_kubectx           = false
  install_stern             = false

  # keep operator module from trying to build OCI CLI from source repo
  install_oci_cli_from_repo = false

  # set to true once your OKE cluster is ready and you want the VM to
  # pull the kubeconfig; leave false to skip the remote-exec step
  generate_kubeconfig = false
} 