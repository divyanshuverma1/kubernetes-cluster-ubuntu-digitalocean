# Create a new Web Droplet in the nyc1 region
variable "number_of_servers"{
	default = 1
}


resource "digitalocean_droplet" "slave" {
  image  = "ubuntu-16-04-x64"
  name   = "${format("slave-%02d", count.index + 1)}"
  count  = "${var.number_of_servers}"
  region = "nyc1"
  size   = "1gb"
  user_data = "${data.template_file.slave_install.rendered}"
  ssh_keys = [
	"${var.digitalocean_ssh_fingerprint}"
  ]

   provisioner "remote-exec" {
        inline = [
            "sudo kubeadm join ${digitalocean_droplet.master.ipv4_address}:6443 --pod-network-cidr=10.244.0.0/16 --token ${module.kubeadm-token.token}",
        ]
        connection {
            type = "ssh",
            user = "root",
            private_key = "${file(var.ssh_private_key)}"
        }

  }

}

data "template_file" "slave_install" {
  template = "${file("${path.module}/slave.tpl")}"
}

output "address_slave" {
  value = "${digitalocean_droplet.slave.*.ipv4_address}"
}

