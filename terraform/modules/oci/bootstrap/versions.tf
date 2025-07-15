terraform {
  required_version = ">= 1.5.0"

  required_providers {
    oci     = { source = "oracle/oci",   version = "~> 6.35" }
    tls     = { source = "hashicorp/tls", version = "~> 4.0"  }
    local   = { source = "hashicorp/local", version = "~> 2.4" }
    doppler = { source = "dopplerhq/doppler", version = "~> 1.3" }
  }
} 