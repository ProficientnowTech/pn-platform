terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.111"
    }
  }
}

variable "pve_node" { type = string }
variable "datastore_id" {
  type    = string
  default = "local-zfs"
}
variable "image_template_id" { type = string }

# Ephemeral LXC that runs the bootstrapper image; nesting = true to host the ephemeral Vault/registry.
# Destroyed at cleanup (phase 7). Repo + age key are pushed in at runtime, never baked.
resource "proxmox_virtual_environment_container" "bootstrapper" {
  node_name    = var.pve_node
  unprivileged = true

  features {
    nesting = true
  }

  initialization {
    hostname = "pn-bootstrapper"
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  network_interface {
    name = "veth0"
  }

  disk {
    datastore_id = var.datastore_id
    size         = 20
  }

  operating_system {
    template_file_id = var.image_template_id
    type             = "debian"
  }
}
