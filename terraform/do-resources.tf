variable "do_token" {
  type = string
}

variable "droplet_ssh_key" {
  type = string
}

variable "docker_install_script_location" {
  type = string
}



provider "digitalocean" {
  token = var.do_token
}

# Create a new SSH key
# resource "digitalocean_ssh_key" "default" {
#   name       = "Terraform Example"
#   public_key = file(var.droplet_ssh_key)
# }



# Create a new Droplet using the SSH key
resource "digitalocean_droplet" "swarm_manager" {
  image    = "ubuntu-18-04-x64"
  name     = "swarm-manager-1"
  region   = "nyc3"
  size     = "s-1vcpu-1gb"
  private_networking = true
  ssh_keys = ["6a:79:7c:65:49:9c:7d:f1:45:39:f2:21:63:23:a2:68"]

  connection {
    user        = "root"
    type        = "ssh"
    private_key = file("/Users/otseobande/.ssh/id_rsa")
    host = self.ipv4_address
  }

  provisioner "file" {
    source      = "../docker-compose.yml"
    destination = "/srv/docker-compose.yml"
  }

  provisioner "remote-exec" {
    scripts = [
      "scripts/docker-install.sh",
      "scripts/start-swarm.sh"
    ]
  }

  provisioner "local-exec" {
    command = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${self.ipv4_address} 'docker swarm join-token -q worker' > token.txt"
  }
}

# Create a new Droplet using the SSH key
resource "digitalocean_droplet" "swarm_worker" {
  image    = "ubuntu-18-04-x64"
  name     = "swarm-worker-1"
  region   = "nyc3"
  size     = "s-1vcpu-1gb"
  private_networking = true
  ssh_keys = ["6a:79:7c:65:49:9c:7d:f1:45:39:f2:21:63:23:a2:68"]

  connection {
    user        = "root"
    type        = "ssh"
    private_key = file("/Users/otseobande/.ssh/id_rsa")
    host = self.ipv4_address
  }

  provisioner "remote-exec" {
    inline = [
      "sh $(${file("scripts/docker-install.sh")})",
      "docker swarm join --token ${trimspace(file("token.txt"))} ${digitalocean_droplet.swarm_manager.ipv4_address_private}:2377"
    ]
  }

  provisioner "local-exec" {
    command = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${digitalocean_droplet.swarm_manager.ipv4_address} 'cd /srv && docker stack deploy --compose-file docker-compose.yml testapp'"
  }
}

resource "digitalocean_loadbalancer" "public" {
  name   = "swarm-load-balancer"
  region = "nyc3"

  forwarding_rule {
    entry_port     = 80
    entry_protocol = "http"

    target_port     = 8080
    target_protocol = "http"
  }

  healthcheck {
    port     = 8080
    protocol = "tcp"
  }

  droplet_ids = [digitalocean_droplet.swarm_manager.id, digitalocean_droplet.swarm_worker.id]
}

output "swarm_manager_ip" {
  value = digitalocean_droplet.swarm_manager.ipv4_address
}

output "swarm_worker_ip" {
  value = digitalocean_droplet.swarm_worker.ipv4_address
}

output "swarm_loadbalancer_ip" {
  value = digitalocean_loadbalancer.public.ip
}

