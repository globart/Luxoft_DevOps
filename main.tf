provider "aws" {
  region = "eu-central-1"
  access_key = "AKIAUOQWZYW4J2REEIVH"
  secret_key = "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"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "docker1" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.allow_web.id]
  key_name                    = "docker"

  provisioner "remote-exec" {
    inline = ["echo 'Wait until SSH is ready'"]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/ansible/docker.pem")
      host        = aws_instance.docker1.public_ip
    }
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i ${aws_instance.docker1.public_ip}, --private-key ${"~/ansible/docker.pem"} docker.yml"
  }

  tags = {
    Name = "Docker1"
  }
}

resource "aws_instance" "docker2" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.allow_web.id]
  key_name                    = "docker"

  provisioner "remote-exec" {
    inline = ["echo 'Wait until SSH is ready'"]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/ansible/docker.pem")
      host        = aws_instance.docker2.public_ip
    }
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i ${aws_instance.docker2.public_ip}, --private-key ${"~/ansible/docker.pem"} docker.yml"
  }

  tags = {
    Name = "Docker2"
  }
}

resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow Web inbound traffic"

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "docker1_ip" {
  value = aws_instance.docker1.public_ip
}

output "docker2_ip" {
  value = aws_instance.docker2.public_ip
}