data "aws_ami" "ubuntu"{
	owners = ["099720109477"]
	most_recent = true

	filter{
		name = "name"
		values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
	}

}

data "aws_subnet" "web"{
	id = var.subnet_id
}

resource "aws_instance" "web-server"{
	instance_type = "t2.micro"
	ami = data.aws_ami.ubuntu.id
	vpc_security_group_ids = [aws_security_group.web-SG.id]
	user_data = file("${path.module}/user-data.sh")
	subnet_id = var.subnet_id
}

resource "aws_security_group" "web-SG"{
	name = "webserver-sercurity-group"
	vpc_id = data.aws_subnet.web.vpc_id

	ingress{
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	egress{
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}

	tags = {
		name = "${var.name}-web-server"
	}
}