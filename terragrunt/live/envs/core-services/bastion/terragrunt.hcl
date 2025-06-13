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
  tag_namespace       = "koci"                       # default tag namespace
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
  instance_display_name = "${include.common.locals.env}-bastion"   # → core-services-bastion
  hostname_label        = "core-services-bastion"                  # must satisfy DNS rules

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
  ssh_public_key  = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCt7qx7y18eFTkCMqOUkNis4FzAlA1oCChMyg5CtIg4lOfvUyG/o4Yxv4vPAR7y85jXbh7Y4LX4z1QvU30Kp3hwb7FYKgXGCnrnZqG0x6AmlhqfmI/UIzpXJKLqGvzI9IJNFBhK19bKnMIqJlunpZ5cAzfmDT7pq4CfMk6GY1PQRd3jDOEwMTaaRdm0fQm/6kNaxlkT9CsD+icUjivwk7DosSUmhBMAso7XNDtn+KyLtEbKFZC6iIXWuXm7kkiD6PYU6FGvfhHrpaz/ttEDf6trmROospdsqv5aaICIa7j6CWAw077MiHrdnGYqAZCC3EKzKDPc2qiqtdLEkAyvM1jR ssh-key-2025-06-11"
  # ssh_public_key  = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEoLDbXep4pEg3nXQk4z29xjkWVnLkPCztbYTd4OPTh5"
#  ssh_public_key = <<EOF
#ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEoLDbXep4pEg3nXQk4z29xjkWVnLkPCztbYTd4OPTh5
#EOF
  #ssh_private_key = get_env("BASTION_SSH_KEY", "") 
               # no key needed when disabled
  ssh_private_key = <<KEY
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
  defined_tags   = {}
  freeform_tags  = include.common.locals.common_tags

  # ── values that were missing (all are required by the module) ──
  timezone            = local.timezone
  upgrade             = true          # run OS package upgrade on first boot
  user                = "kociadmin"     # extra Linux user to create

  tag_namespace   = local.tag_namespace
  use_defined_tags = false            # set true if you actually supply them
} 