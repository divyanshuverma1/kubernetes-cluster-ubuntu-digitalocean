# Create a new Web Droplet in the nyc2 region
resource "digitalocean_droplet" "master" {
  image  = "ubuntu-16-04-x64"
  name   = "master"
  region = "nyc1"
  size   = "1gb"
  user_data = "${data.template_file.master_install.rendered}"
  ssh_keys = [
	"${var.digitalocean_ssh_fingerprint}"
  ]

  # kubeadm setup
  provisioner "remote-exec" {
        inline = [
            "sudo kubeadm init ${digitalocean_droplet.master.ipv4_address}:6443 --pod-network-cidr=10.244.0.0/16 --token ${module.kubeadm-token.token}",
            "sudo mkdir -p /root/.kube",
            "sudo cp -i /etc/kubernetes/admin.conf /root/.kube/config",
            "sudo chown root:root /root/.kube/config",
            "sudo kubectl create -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml",
        ]
        connection {
            type = "ssh",
            user = "root",
            private_key = "${file(var.ssh_private_key)}"
        }

  }
}

data "template_file" "master_install" {
  template = "${file("${path.module}/master.tpl")}"
}

output "address_master" {
  value = "${digitalocean_droplet.master.ipv4_address}"
}

