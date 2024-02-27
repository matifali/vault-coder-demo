terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

data "coder_provisioner" "me" {}

provider "docker" {}

data "coder_workspace" "me" {}

# module "vault-github" {
#   source      = "registry.coder.com/modules/vault-github/coder"
#   version     = "1.0.7"
#   agent_id   = coder_agent.main.id
#   vault_addr = "https://vault.company.com"
# }

variable "hcp_client_id" {
  type        = string
  description = <<-EOF
  The client ID for the HCP Vault Secrets service principal. (Optional if HCP_CLIENT_ID is set as an environment variable.)
  EOF
  sensitive   = true
}

variable "hcp_client_secret" {
  type        = string
  description = <<-EOF
  The client secret for the HCP Vault Secrets service principal. (Optional if HCP_CLIENT_SECRET is set as an environment variable.)
  EOF
  sensitive   = true
}

module "vault" {
  source        = "registry.coder.com/modules/hcp-vault-secrets/coder"
  version       = "1.0.7"
  agent_id      = coder_agent.main.id
  project_id    = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  client_id     = var.hcp_client_id
  client_secret = var.hcp_client_secret
  app_name      = "demo-app"
}

module "git-clone" {
  source   = "registry.coder.com/modules/git-clone/coder"
  version  = "1.0.3"
  agent_id = coder_agent.main.id
  url      = "https://github.com/matifali/vault-coder-demo"
}

module "git-config" {
  source                = "registry.coder.com/modules/git-config/coder"
  version               = "1.0.2"
  agent_id              = coder_agent.main.id
  allow_username_change = false
  allow_email_change    = false
}

module "vscode-web" {
  source         = "registry.coder.com/modules/vscode-web/coder"
  version        = "1.0.6"
  agent_id       = coder_agent.main.id
  folder         = "/home/coder/vault-coder-demo"
  extensions     = ["github.copilot", "ms-python.python"]
  accept_license = true
}

resource "coder_agent" "main" {
  arch = data.coder_provisioner.me.arch
  os   = "linux"
  dir  = module.git-clone.repo_dir
  startup_script = <<-EOF
    pip install flask
  EOF

  metadata {
    display_name = "CPU Usage"
    key          = "0_cpu_usage"
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "RAM Usage"
    key          = "1_ram_usage"
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }
}

resource "docker_image" "main" {
  name = "coder-${data.coder_workspace.me.id}"
  build {
    context = "./build"
  }
  triggers = {
    dir_sha1 = sha1(join("", [for f in fileset(path.module, "build/*") : filesha1(f)]))
  }
}

resource "docker_container" "workspace" {
  count = data.coder_workspace.me.start_count
  image = docker_image.main.name
  # Uses lower() to avoid Docker restriction on container names.
  name = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
  # Hostname makes the shell more user friendly: coder@my-workspace:~$
  hostname = data.coder_workspace.me.name
  entrypoint = ["sh", "-c", coder_agent.main.init_script]
  env        = ["CODER_AGENT_TOKEN=${coder_agent.main.token}"]
  restart    = "unless-stopped"
  host {
    host = "host.docker.internal"
    ip   = "host-gateway"
  }
  volumes {
    container_path = "/home/coder"
    volume_name    = docker_volume.home_volume.name
    read_only      = false
  }
  # Add labels in Docker to keep track of orphan resources.
  labels {
    label = "coder.owner"
    value = data.coder_workspace.me.owner
  }
  labels {
    label = "coder.owner_id"
    value = data.coder_workspace.me.owner_id
  }
  labels {
    label = "coder.workspace_id"
    value = data.coder_workspace.me.id
  }
  labels {
    label = "coder.workspace_name"
    value = data.coder_workspace.me.name
  }
}

resource "docker_volume" "home_volume" {
  name = "coder-${data.coder_workspace.me.id}-home"
  # Protect the volume from being deleted due to changes in attributes.
  lifecycle {
    ignore_changes = all
  }
  # Add labels in Docker to keep track of orphan resources.
  labels {
    label = "coder.owner"
    value = data.coder_workspace.me.owner
  }
  labels {
    label = "coder.owner_id"
    value = data.coder_workspace.me.owner_id
  }
  labels {
    label = "coder.workspace_id"
    value = data.coder_workspace.me.id
  }
}