packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "aws_region" {
  default = "eu-north-1"
}

source "amazon-ebs" "ubuntu" {
  region                 = var.aws_region
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      virtualization-type = "hvm"
      root-device-type    = "ebs"
    }
    most_recent = true
    owners      = ["099720109477"] # Canonical
  }
  instance_type          = "t2.micro"
  ssh_username           = "ubuntu"
  ami_name               = "cloud-computing-uppgift"
}

build {
  sources = ["source.amazon-ebs.ubuntu"]

  # Kopiera över .jar fil
  provisioner "file" {
    source      = "cmdb.jar"
    destination = "/tmp/cmdb.jar"
  }

  provisioner "shell" {
    inline = [
      "sudo apt update",
      "sudo apt install -y openjdk-21-jdk", # Installera java

      "sudo mv /tmp/cmdb.jar /opt/cmdb.jar",
      "sudo chown root:root /opt/cmdb.jar",

      # Skapa systemd service
      "sudo tee /etc/systemd/system/myapp.service > /dev/null <<EOF",
      "[Unit]",
      "Description=Spring Boot App",
      "After=network.target",
      "",
      "[Service]",
      "EnvironmentFile=/etc/cmdb.env", # Denna finns inte än och kommer därför resultera i error, det är avsiktligt
      "ExecStart=/usr/bin/java -jar /opt/cmdb.jar",
      "SuccessExitStatus=143",
      "Restart=always",
      "User=root",
      "",
      "[Install]",
      "WantedBy=multi-user.target",
      "EOF",
      "sudo systemctl enable myapp.service"
    ]
  }
}